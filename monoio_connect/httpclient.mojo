from memory import stack_allocation, UnsafePointer
from collections import Dict
from utils import StringRef
from .log import logd
from .internal.monoio import (
    MonoioRuntimePtr,
    create_monoio_runtime,
    destroy_monoio_runtime,
)
from .internal.httpclient import (
    ClientBuilderPtr,
    HttpClientPtr,
    HttpRequestPtr,
    HeaderMapPtr,
    create_client_builder,
    create_header_map,
    header_map_set,
    client_builder_default_headers,
    client_builder_max_idle_connections,
    client_builder_idle_connection_timeout,
    client_builder_set_read_timeout,
    client_builder_initial_max_streams,
    client_builder_enable_https,
    client_builder_http1_only,
    client_builder_build_with_runtime,
    http_request_set_header,
    destroy_http_request,
    new_http_request,
    destroy_client_builder,
    destroy_http_client,
    destroy_header_map,
    http_client_request,
    http_client_request_with_callback,
    destroy_http_response,
    http_response_status_code,
    http_response_body,
    HttpResponsePtr,
    HttpResponseCallback,
)
from .internal import c_void


@value
struct QueryStringBuilder:
    var data: Dict[String, String]

    fn __init__(out self):
        self.data = Dict[String, String]()

    fn __setitem__(mut self, name: String, value: String):
        self.data[name] = value

    fn to_string(self) raises -> String:
        if len(self.data) == 0:
            return ""

        var url = String("?")
        for item in self.data.items():
            url += item[].key + "=" + item[].value + "&"
        return url[1:-1]

    fn debug(mut self) raises:
        for item in self.data.items():
            logi(
                # str(i)
                # + ": "
                str(item[].key)
                + " = "
                + str(item[].value)
            )


@value
struct HttpClientOptions:
    """
    HttpClient 构造函数的参数.
    """

    var base_url: String

    fn __init__(out self, base_url: String):
        self.base_url = base_url


alias Headers = Dict[String, String]


@value
struct HttpResponse(Stringable):
    var status_code: Int
    var text: String

    fn __init__(out self, status_code: Int, text: String):
        self.status_code = status_code
        self.text = text

    fn __str__(self) -> String:
        return String.write(
            "[",
            str(self.status_code),
            " ",
            http_status_code_to_string(self.status_code),
            "] ",
            self.text,
        )


@always_inline
fn http_status_code_to_string(code: Int) -> String:
    if code == 200:
        return "OK"
    elif code == 404:
        return "Not Found"
    elif code == 500:
        return "Internal Server Error"
    else:
        return "Unknown"


@value
@register_passable("trivial")
struct Method(Stringable):
    var _value: UInt8

    alias METHOD_OPTIONS = Method(0)
    alias METHOD_GET = Method(1)
    alias METHOD_POST = Method(2)
    alias METHOD_PUT = Method(3)
    alias METHOD_DELETE = Method(4)
    alias METHOD_HEAD = Method(5)
    alias METHOD_TRACE = Method(6)
    alias METHOD_CONNECT = Method(7)
    alias METHOD_PATCH = Method(8)

    fn __eq__(self, other: Method) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == Method.METHOD_OPTIONS:
            return "OPTIONS"
        elif self == Method.METHOD_GET:
            return "GET"
        elif self == Method.METHOD_POST:
            return "POST"
        elif self == Method.METHOD_PUT:
            return "PUT"
        elif self == Method.METHOD_DELETE:
            return "DELETE"
        elif self == Method.METHOD_HEAD:
            return "HEAD"
        elif self == Method.METHOD_TRACE:
            return "TRACE"
        elif self == Method.METHOD_CONNECT:
            return "CONNECT"
        elif self == Method.METHOD_PATCH:
            return "PATCH"
        else:
            return "UNKNOWN"


@value
@register_passable("trivial")
struct HttpVersion(Stringable):
    var _value: UInt8

    alias HTTP_VERSION_HTTP09 = HttpVersion(0)
    alias HTTP_VERSION_HTTP10 = HttpVersion(1)
    alias HTTP_VERSION_HTTP11 = HttpVersion(2)
    alias HTTP_VERSION_H2 = HttpVersion(3)
    alias HTTP_VERSION_H3 = HttpVersion(4)
    alias HTTP_VERSION___NON_EXHAUSTIVE = HttpVersion(5)

    fn __eq__(self, other: HttpVersion) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == HttpVersion.HTTP_VERSION_HTTP09:
            return "HTTP/0.9"
        elif self == HttpVersion.HTTP_VERSION_HTTP10:
            return "HTTP/1.0"
        elif self == HttpVersion.HTTP_VERSION_HTTP11:
            return "HTTP/1.1"
        elif self == HttpVersion.HTTP_VERSION_H2:
            return "HTTP/2"
        elif self == HttpVersion.HTTP_VERSION_H3:
            return "HTTP/3"
        else:
            return "UNKNOWN"


struct HttpClient:
    var _builder: ClientBuilderPtr
    var _client: HttpClientPtr
    var _headers: HeaderMapPtr
    var _rt: MonoioRuntimePtr
    var _base_url: String
    var _verbose: Bool

    fn __init__(
        out self,
        options: HttpClientOptions,
        rt: MonoioRuntimePtr = MonoioRuntimePtr(),
        verbose: Bool = False,
    ):
        self._rt = rt if rt != MonoioRuntimePtr() else create_monoio_runtime()
        self._builder = create_client_builder()
        self._headers = create_header_map()
        var key = String("User-Agent")
        var value = String("Mojo")
        header_map_set(
            self._headers, key.unsafe_cstr_ptr(), value.unsafe_cstr_ptr()
        )
        client_builder_default_headers(self._builder, self._headers)
        # client_builder_disable_connection_pool(self._builder)
        client_builder_max_idle_connections(self._builder, 10)
        client_builder_idle_connection_timeout(self._builder, 30)
        client_builder_set_read_timeout(self._builder, 30)
        # client_builder_initial_max_streams(self._builder, 100)
        # client_builder_max_concurrent_streams(self._builder, 100)
        client_builder_enable_https(self._builder)
        client_builder_http1_only(self._builder)
        # self._client = client_builder_build(self._builder)
        self._client = client_builder_build_with_runtime(
            self._rt, self._builder
        )
        self._base_url = options.base_url
        self._verbose = verbose

    fn __del__(owned self):
        if self._builder:
            destroy_client_builder(self._builder)
        if self._client:
            destroy_http_client(self._client)
        if self._headers:
            destroy_header_map(self._headers)
        destroy_monoio_runtime(self._rt)

    @always_inline
    fn request[
        max_body_size: Int = 1024 * 1000
    ](
        self,
        path: String,
        method: Method,
        headers: Headers,
        payload: String,
    ) raises -> HttpResponse:
        var url = self._base_url + path
        if self._verbose:
            logd(String.format("Request: {} {}", str(method), url))
            if len(payload):
                logd("Request payload:")
                logd(payload)
        var req = new_http_request(
            method,
            url.unsafe_cstr_ptr(),
            HttpVersion.HTTP_VERSION_HTTP11,
            payload.unsafe_cstr_ptr(),
        )
        for item in headers.items():
            http_request_set_header(
                req,
                item[].key.unsafe_cstr_ptr(),
                item[].value.unsafe_cstr_ptr(),
            )
        if self._verbose:
            logd("Request headers:")
            for item in headers.items():
                logd(item[].key + ": " + item[].value)
        # retry 3 times
        for i in range(3):
            var ret = self.request_internal[max_body_size](req)
            if ret.status_code != 0:
                destroy_http_request(req)
                if self._verbose:
                    logd("Request succeeded: " + str(ret))
                return ret
            if self._verbose:
                logd(
                    "Request failed, status_code: "
                    + str(ret.status_code)
                    + ", retrying "
                    + str(i)
                    + "/3"
                )
        destroy_http_request(req)
        if self._verbose:
            logw("request failed")
        return HttpResponse(0, "")

    @always_inline
    fn request_internal[
        max_body_size: Int = 1024 * 1000
    ](self, req: HttpRequestPtr,) -> HttpResponse:
        var resp = http_client_request(self._rt, self._client, req)
        var status_code = int(http_response_status_code(resp))
        var buf = stack_allocation[max_body_size, Int8]()
        var body = http_response_body(resp, buf, max_body_size)
        var ret = HttpResponse(status_code, String(StringRef(buf, body)))
        destroy_http_response(resp)
        return ret

    @always_inline
    fn request_with_callback(
        self,
        path: String,
        method: Method,
        headers: Headers,
        payload: String,
        req_id: UInt64,
        cb: HttpResponseCallback,
    ) -> None:
        var url = self._base_url + path
        logd("url: " + url)
        var req = new_http_request(
            method,
            url.unsafe_cstr_ptr(),
            HttpVersion.HTTP_VERSION_HTTP11,
            payload.unsafe_cstr_ptr(),
        )
        for item in headers.items():
            http_request_set_header(
                req,
                item[].key.unsafe_cstr_ptr(),
                item[].value.unsafe_cstr_ptr(),
            )
            # logd("key: " + item[].key + " value: " + item[].value)
        http_client_request_with_callback(
            self._rt, self._client, req, req_id, 0, UnsafePointer[c_void](), cb
        )
        # var resp = http_client_request(self._rt, self._client, req)
        # var status_code = int(http_response_status_code(resp))
        # alias max_body_size: Int = 1024 * 1000
        # var buf = stack_allocation[max_body_size, Int8]()
        # var body = http_response_body(resp, buf, max_body_size)
        # var ret = HttpResponse(status_code, String(StringRef(buf, body)))
        # logd("status_code: " + str(status_code))
        # logd("body: " + ret.text)
        # destroy_http_response(resp)
        # destroy_http_request(req)

    fn test(self):
        var method = Method.METHOD_GET
        var url = String("https://www.baidu.com")
        var version = HttpVersion.HTTP_VERSION_HTTP11
        var payload = String("")
        var req = new_http_request(
            method, url.unsafe_cstr_ptr(), version, payload.unsafe_cstr_ptr()
        )
        var resp = http_client_request(self._rt, self._client, req)
        var status_code = http_response_status_code(resp)
        var buf = stack_allocation[102400, Int8]()
        var body = http_response_body(resp, buf, 102400)
        print("status_code: ", status_code)
        print("body: ", String(StringRef(buf, body)))
        destroy_http_request(req)
        destroy_http_response(resp)
        # destroy_monoio_runtime(rt)
