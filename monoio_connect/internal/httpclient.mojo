from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t, external_call


alias HeaderMapPtr = UnsafePointer[c_void]
alias HttpRequestPtr = UnsafePointer[c_void]
alias HttpResponsePtr = UnsafePointer[c_void]
alias HttpClientPtr = UnsafePointer[c_void]
alias ClientBuilderPtr = UnsafePointer[c_void]

alias fn_create_header_map = fn () -> HeaderMapPtr
alias fn_destroy_header_map = fn (header_map: HeaderMapPtr) -> None
alias fn_header_map_get = fn (
    header_map: HeaderMapPtr, key: c_char_ptr, out: c_char_ptr
) -> c_size_t
alias fn_header_map_set = fn (
    header_map: HeaderMapPtr, key: c_char_ptr, value: c_char_ptr
) -> None

alias fn_create_client_builder = fn () -> ClientBuilderPtr
alias fn_destroy_client_builder = fn (client_builder: ClientBuilderPtr) -> None
alias fn_client_builder_default_headers = fn (
    client_builder: ClientBuilderPtr, header_map: HeaderMapPtr
) -> None
alias fn_client_builder_disable_connection_pool = fn (
    client_builder: ClientBuilderPtr
) -> None
alias fn_client_builder_max_idle_connections = fn (
    client_builder: ClientBuilderPtr, val: c_size_t
) -> None
alias fn_client_builder_idle_connection_timeout = fn (
    client_builder: ClientBuilderPtr, val: UInt64
) -> None

alias fn_client_builder_set_read_timeout = fn (
    client_builder: ClientBuilderPtr, val: UInt64
) -> None

alias fn_client_builder_initial_max_streams = fn (
    client_builder: ClientBuilderPtr, val: c_size_t
) -> None

alias fn_client_builder_max_concurrent_streams = fn (
    client_builder: ClientBuilderPtr, val: c_uint32
) -> None

alias fn_client_builder_http1_only = fn (
    client_builder: ClientBuilderPtr
) -> None

alias fn_client_builder_http2_prior_knowledge = fn (
    client_builder: ClientBuilderPtr
) -> None

alias fn_client_builder_enable_https = fn (
    client_builder: ClientBuilderPtr
) -> None

alias fn_client_builder_build = fn (
    client_builder: ClientBuilderPtr
) -> HttpClientPtr

alias fn_client_builder_build_with_runtime = fn (
    runtime: MonoioRuntimePtr, client_builder: ClientBuilderPtr
) -> HttpClientPtr

alias fn_new_http_request = fn (
    method: c_uint8, url: c_char_ptr, version: c_uint8, body: c_char_ptr
) -> HttpRequestPtr

alias fn_destroy_http_request = fn (req: HttpRequestPtr) -> None

alias fn_http_request_set_header = fn (
    req: HttpRequestPtr, key: c_char_ptr, value: c_char_ptr
) -> None

alias fn_http_client_request = fn (
    runtime: MonoioRuntimePtr, c: HttpClientPtr, req: HttpRequestPtr
) -> HttpResponsePtr

alias HttpResponseCallback = fn (
    req_id: UInt64,
    type_: UInt32,
    source: UnsafePointer[c_void],
    res: HttpResponsePtr,
) -> None

alias fn_http_client_request_with_callback = fn (
    runtime: MonoioRuntimePtr,
    c: HttpClientPtr,
    req: HttpRequestPtr,
    req_id: UInt64,
    type_: UInt32,
    source: UnsafePointer[c_void],
    cb: HttpResponseCallback,
) -> None

alias fn_destroy_http_client = fn (c: HttpClientPtr) -> None

alias fn_destroy_http_response = fn (resp: HttpResponsePtr) -> None

alias fn_http_response_status_code = fn (resp: HttpResponsePtr) -> c_uint16

alias fn_http_response_body = fn (
    resp: HttpResponsePtr, result: c_char_ptr, len: c_size_t
) -> c_size_t

alias fn_test_http_client = fn () -> None

alias fn_test_monoiohttpclient = fn () -> None

var _handle: DLHandle = DLHandle(LIBNAME)

var _create_header_map = _handle.get_function[fn_create_header_map](
    "create_header_map"
)

var _destroy_header_map = _handle.get_function[fn_destroy_header_map](
    "destroy_header_map"
)

var _header_map_get = _handle.get_function[fn_header_map_get]("header_map_get")

var _header_map_set = _handle.get_function[fn_header_map_set]("header_map_set")

var _create_client_builder = _handle.get_function[fn_create_client_builder](
    "create_client_builder"
)

var _destroy_client_builder = _handle.get_function[fn_destroy_client_builder](
    "destroy_client_builder"
)

var _client_builder_default_headers = _handle.get_function[
    fn_client_builder_default_headers
]("client_builder_default_headers")

var _client_builder_disable_connection_pool = _handle.get_function[
    fn_client_builder_disable_connection_pool
]("client_builder_disable_connection_pool")

var _client_builder_max_idle_connections = _handle.get_function[
    fn_client_builder_max_idle_connections
]("client_builder_max_idle_connections")

var _client_builder_idle_connection_timeout = _handle.get_function[
    fn_client_builder_idle_connection_timeout
]("client_builder_idle_connection_timeout")

var _client_builder_set_read_timeout = _handle.get_function[
    fn_client_builder_set_read_timeout
]("client_builder_set_read_timeout")

var _client_builder_initial_max_streams = _handle.get_function[
    fn_client_builder_initial_max_streams
]("client_builder_initial_max_streams")

var _client_builder_max_concurrent_streams = _handle.get_function[
    fn_client_builder_max_concurrent_streams
]("client_builder_max_concurrent_streams")

var _client_builder_http1_only = _handle.get_function[
    fn_client_builder_http1_only
]("client_builder_http1_only")

var _client_builder_http2_prior_knowledge = _handle.get_function[
    fn_client_builder_http2_prior_knowledge
]("client_builder_http2_prior_knowledge")

var _client_builder_enable_https = _handle.get_function[
    fn_client_builder_enable_https
]("client_builder_enable_https")

var _client_builder_build = _handle.get_function[fn_client_builder_build](
    "client_builder_build"
)
var _client_builder_build_with_runtime = _handle.get_function[
    fn_client_builder_build_with_runtime
]("client_builder_build_with_runtime")

var _new_http_request = _handle.get_function[fn_new_http_request](
    "new_http_request"
)

var _destroy_http_request = _handle.get_function[fn_destroy_http_request](
    "destroy_http_request"
)

var _http_request_set_header = _handle.get_function[fn_http_request_set_header](
    "http_request_set_header"
)

var _http_client_request = _handle.get_function[fn_http_client_request](
    "http_client_request"
)

var _http_client_request_with_callback = _handle.get_function[
    fn_http_client_request_with_callback
]("http_client_request_with_callback")

var _destroy_http_client = _handle.get_function[fn_destroy_http_client](
    "destroy_http_client"
)

var _destroy_http_response = _handle.get_function[fn_destroy_http_response](
    "destroy_http_response"
)

var _http_response_status_code = _handle.get_function[
    fn_http_response_status_code
]("http_response_status_code")

var _http_response_body = _handle.get_function[fn_http_response_body](
    "http_response_body"
)

var _test_http_client = _handle.get_function[fn_test_http_client](
    "test_http_client"
)

var _test_monoiohttpclient = _handle.get_function[fn_test_monoiohttpclient](
    "test_monoiohttpclient"
)


@always_inline
fn create_header_map() -> HeaderMapPtr:
    @parameter
    if is_static_build():
        return external_call["create_header_map", HeaderMapPtr]()
    else:
        return _create_header_map()


@always_inline
fn destroy_header_map(header_map: HeaderMapPtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_header_map", NoneType](header_map)
    else:
        return _destroy_header_map(header_map)


@always_inline
fn header_map_get(
    header_map: HeaderMapPtr, key: c_char_ptr, out: c_char_ptr
) -> c_size_t:
    @parameter
    if is_static_build():
        return external_call["header_map_get", c_size_t](header_map, key, out)
    else:
        return _header_map_get(header_map, key, out)


@always_inline
fn header_map_set(
    header_map: HeaderMapPtr, key: c_char_ptr, value: c_char_ptr
) -> None:
    @parameter
    if is_static_build():
        external_call["header_map_set", NoneType](header_map, key, value)
    else:
        return _header_map_set(header_map, key, value)


@always_inline
fn create_client_builder() -> ClientBuilderPtr:
    @parameter
    if is_static_build():
        return external_call["create_client_builder", ClientBuilderPtr]()
    else:
        return _create_client_builder()


@always_inline
fn destroy_client_builder(client_builder: ClientBuilderPtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_client_builder", NoneType](client_builder)
    else:
        return _destroy_client_builder(client_builder)


@always_inline
fn client_builder_default_headers(
    client_builder: ClientBuilderPtr, header_map: HeaderMapPtr
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_default_headers", NoneType](
            client_builder, header_map
        )
    else:
        return _client_builder_default_headers(client_builder, header_map)


@always_inline
fn client_builder_disable_connection_pool(
    client_builder: ClientBuilderPtr,
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_disable_connection_pool", NoneType](
            client_builder
        )
    else:
        return _client_builder_disable_connection_pool(client_builder)


@always_inline
fn client_builder_max_idle_connections(
    client_builder: ClientBuilderPtr, val: c_size_t
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_max_idle_connections", NoneType](
            client_builder, val
        )
    else:
        return _client_builder_max_idle_connections(client_builder, val)


@always_inline
fn client_builder_idle_connection_timeout(
    client_builder: ClientBuilderPtr, val: UInt64
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_idle_connection_timeout", NoneType](
            client_builder, val
        )
    else:
        return _client_builder_idle_connection_timeout(client_builder, val)


@always_inline
fn client_builder_set_read_timeout(
    client_builder: ClientBuilderPtr, val: UInt64
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_set_read_timeout", NoneType](
            client_builder, val
        )
    else:
        return _client_builder_set_read_timeout(client_builder, val)


@always_inline
fn client_builder_initial_max_streams(
    client_builder: ClientBuilderPtr, val: c_size_t
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_initial_max_streams", NoneType](
            client_builder, val
        )
    else:
        return _client_builder_initial_max_streams(client_builder, val)


@always_inline
fn client_builder_max_concurrent_streams(
    client_builder: ClientBuilderPtr, val: c_uint32
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_max_concurrent_streams", NoneType](
            client_builder, val
        )
    else:
        return _client_builder_max_concurrent_streams(client_builder, val)


@always_inline
fn client_builder_http1_only(client_builder: ClientBuilderPtr) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_http1_only", NoneType](client_builder)
    else:
        return _client_builder_http1_only(client_builder)


@always_inline
fn client_builder_http2_prior_knowledge(
    client_builder: ClientBuilderPtr,
) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_http2_prior_knowledge", NoneType](
            client_builder
        )
    else:
        return _client_builder_http2_prior_knowledge(client_builder)


@always_inline
fn client_builder_enable_https(client_builder: ClientBuilderPtr) -> None:
    @parameter
    if is_static_build():
        external_call["client_builder_enable_https", NoneType](client_builder)
    else:
        return _client_builder_enable_https(client_builder)


@always_inline
fn client_builder_build(client_builder: ClientBuilderPtr) -> HttpClientPtr:
    @parameter
    if is_static_build():
        return external_call["client_builder_build", HttpClientPtr](
            client_builder
        )
    else:
        return _client_builder_build(client_builder)


@always_inline
fn client_builder_build_with_runtime(
    runtime: MonoioRuntimePtr, client_builder: ClientBuilderPtr
) -> HttpClientPtr:
    @parameter
    if is_static_build():
        return external_call[
            "client_builder_build_with_runtime", HttpClientPtr
        ](runtime, client_builder)
    else:
        return _client_builder_build_with_runtime(runtime, client_builder)


@always_inline
fn new_http_request(
    method: Method, url: c_char_ptr, version: HttpVersion, body: c_char_ptr
) -> HttpRequestPtr:
    @parameter
    if is_static_build():
        return external_call["new_http_request", HttpRequestPtr](
            method._value, url, version._value, body
        )
    else:
        return _new_http_request(method._value, url, version._value, body)


@always_inline
fn destroy_http_request(req: HttpRequestPtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_http_request", NoneType](req)
    else:
        return _destroy_http_request(req)


@always_inline
fn http_request_set_header(
    req: HttpRequestPtr, key: c_char_ptr, value: c_char_ptr
) -> None:
    @parameter
    if is_static_build():
        external_call["http_request_set_header", NoneType](req, key, value)
    else:
        return _http_request_set_header(req, key, value)


@always_inline
fn http_client_request(
    runtime: MonoioRuntimePtr, c: HttpClientPtr, req: HttpRequestPtr
) -> HttpResponsePtr:
    @parameter
    if is_static_build():
        return external_call["http_client_request", HttpResponsePtr](
            runtime, c, req
        )
    else:
        return _http_client_request(runtime, c, req)


@always_inline
fn http_client_request_with_callback(
    runtime: MonoioRuntimePtr,
    c: HttpClientPtr,
    req: HttpRequestPtr,
    req_id: UInt64,
    type_: UInt32,
    source: UnsafePointer[c_void],
    cb: HttpResponseCallback,
) -> None:
    @parameter
    if is_static_build():
        external_call["http_client_request_with_callback", NoneType](
            runtime, c, req, req_id, type_, source, cb
        )
    else:
        return _http_client_request_with_callback(
            runtime, c, req, req_id, type_, source, cb
        )


@always_inline
fn destroy_http_client(c: HttpClientPtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_http_client", NoneType](c)
    else:
        return _destroy_http_client(c)


@always_inline
fn destroy_http_response(resp: HttpResponsePtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_http_response", NoneType](resp)
    else:
        return _destroy_http_response(resp)


@always_inline
fn http_response_status_code(resp: HttpResponsePtr) -> c_uint16:
    @parameter
    if is_static_build():
        return external_call["http_response_status_code", c_uint16](resp)
    else:
        return _http_response_status_code(resp)


@always_inline
fn http_response_body(
    resp: HttpResponsePtr, result: c_char_ptr, len: c_size_t
) -> c_size_t:
    @parameter
    if is_static_build():
        return external_call["http_response_body", c_size_t](resp, result, len)
    else:
        return _http_response_body(resp, result, len)


@always_inline
fn test_http_client():
    @parameter
    if is_static_build():
        external_call["test_http_client", NoneType]()
    else:
        return _test_http_client()


@always_inline
fn test_monoiohttpclient():
    @parameter
    if is_static_build():
        external_call["test_monoiohttpclient", NoneType]()
    else:
        return _test_monoiohttpclient()
