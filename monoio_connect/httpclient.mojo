from memory import stack_allocation
from collections import Dict
from .log import logd


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
struct HttpResponse:
    var status_code: Int
    var text: String

    fn __init__(out self, status_code: Int, text: String):
        self.status_code = status_code
        self.text = text


struct HttpClient:
    var _builder: ClientBuilderPtr
    var _client: HttpClientPtr
    var _headers: HeaderMapPtr
    var _rt: MonoioRuntimePtr
    var _base_url: String

    fn __init__(
        out self,
        options: HttpClientOptions,
        rt: MonoioRuntimePtr = MonoioRuntimePtr(),
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
        client_builder_idle_connection_timeout(self._builder, 10)
        client_builder_set_read_timeout(self._builder, 10)
        # client_builder_initial_max_streams(self._builder, 100)
        # client_builder_max_concurrent_streams(self._builder, 100)
        client_builder_enable_https(self._builder)
        client_builder_http1_only(self._builder)
        self._client = client_builder_build(self._builder)
        self._base_url = options.base_url

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
    ) -> HttpResponse:
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
        var resp = http_client_request(self._rt, self._client, req)
        var status_code = int(http_response_status_code(resp))
        var buf = stack_allocation[max_body_size, Int8]()
        var body = http_response_body(resp, buf, max_body_size)
        var ret = HttpResponse(status_code, String(StringRef(buf, body)))
        destroy_http_response(resp)
        destroy_http_request(req)
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
