from collections.dict import Dict
from memory import UnsafePointer
from utils import StringRef
from sys.ffi import _Global
from .internal import c_void, StrBoxed, free_str
from .internal.fastwebsockets import connect_ws, ws_send_text
from .log import logt, logd, logi, logw, loge


alias WebSocketOpenCallback = fn () escaping -> None
alias WebSocketMessageCallback = fn (msg: String) escaping -> None
alias WebSocketPingCallback = fn () escaping -> None
alias WebSocketErrorCallback = fn (err: String) escaping -> None
alias WebSocketCloseCallback = fn () escaping -> None
alias WebSocketTimerCallback = fn (count: UInt64) escaping -> None

alias WebSocketMap = Dict[Int, UnsafePointer[WebSocket]]

alias WebSocketOpenCallbacks = Dict[Int, WebSocketOpenCallback]
alias WebSocketMessageCallbacks = Dict[Int, WebSocketMessageCallback]
alias WebSocketPingCallbacks = Dict[Int, WebSocketPingCallback]
alias WebSocketErrorCallbacks = Dict[Int, WebSocketErrorCallback]
alias WebSocketCloseCallbacks = Dict[Int, WebSocketCloseCallback]
alias WebSocketTimerCallbacks = Dict[Int, WebSocketTimerCallback]


alias WS_MAP = _Global[
    "WS_MAP",
    WebSocketMap,
    _init_ws_map,
]

alias WS_OPEN_CB = _Global[
    "WS_OPEN_CB",
    WebSocketOpenCallbacks,
    _init_ws_on_open_callbacks,
]
alias WS_MSG_CB = _Global[
    "WS_MSG_CB",
    WebSocketMessageCallbacks,
    _init_ws_on_message_callbacks,
]
alias WS_PING_CB = _Global[
    "WS_PING_CB",
    WebSocketPingCallbacks,
    _init_ws_on_ping_callbacks,
]
alias WS_ERR_CB = _Global[
    "WS_ERR_CB",
    WebSocketErrorCallbacks,
    _init_ws_on_error_callbacks,
]
alias WS_CLOSE_CB = _Global[
    "WS_CLOSE_CB",
    WebSocketCloseCallbacks,
    _init_ws_on_close_callbacks,
]
alias WS_TIMER_CB = _Global[
    "WS_TIMER_CB",
    WebSocketTimerCallbacks,
    _init_ws_on_timer_callbacks,
]


fn _init_ws_map() -> WebSocketMap:
    return WebSocketMap()


fn _init_ws_on_open_callbacks() -> WebSocketOpenCallbacks:
    return WebSocketOpenCallbacks()


fn _init_ws_on_message_callbacks() -> WebSocketMessageCallbacks:
    return WebSocketMessageCallbacks()


fn _init_ws_on_ping_callbacks() -> WebSocketPingCallbacks:
    return WebSocketPingCallbacks()


fn _init_ws_on_error_callbacks() -> WebSocketErrorCallbacks:
    return WebSocketErrorCallbacks()


fn _init_ws_on_close_callbacks() -> WebSocketCloseCallbacks:
    return WebSocketCloseCallbacks()


fn _init_ws_on_timer_callbacks() -> WebSocketTimerCallbacks:
    return WebSocketTimerCallbacks()


fn ws_map_ptr() -> UnsafePointer[WebSocketMap]:
    return WS_MAP.get_or_create_ptr()


fn ws_open_callbacks_ptr() -> UnsafePointer[WebSocketOpenCallbacks]:
    return WS_OPEN_CB.get_or_create_ptr()


fn ws_message_callbacks_ptr() -> UnsafePointer[WebSocketMessageCallbacks]:
    return WS_MSG_CB.get_or_create_ptr()


fn ws_ping_callbacks_ptr() -> UnsafePointer[WebSocketPingCallbacks]:
    return WS_PING_CB.get_or_create_ptr()


fn ws_error_callbacks_ptr() -> UnsafePointer[WebSocketErrorCallbacks]:
    return WS_ERR_CB.get_or_create_ptr()


fn ws_close_callbacks_ptr() -> UnsafePointer[WebSocketCloseCallbacks]:
    return WS_CLOSE_CB.get_or_create_ptr()


fn ws_timer_callbacks_ptr() -> UnsafePointer[WebSocketTimerCallbacks]:
    return WS_TIMER_CB.get_or_create_ptr()


fn _ws_on_open(id: Int64, ws: UnsafePointer[c_void]) -> None:
    logt("ws_on_open ws: " + String(ws) + " ws_id: " + String(Int(ws)))
    var id_ = Int(id)
    try:
        var ws_ = ws_map_ptr()[][id_]
        ws_[]._set_ws(ws)
        ws_open_callbacks_ptr()[][id_]()
    except e:
        pass


fn _ws_on_message(id: Int64, ws: UnsafePointer[c_void], msg: StrBoxed) -> None:
    logt("ws_on_message ws: " + String(ws))
    var s = String(StringRef(msg.ptr, msg.len))
    try:
        ws_message_callbacks_ptr()[][Int(id)](s)
    except e:
        pass
    free_str(msg)


fn _ws_on_ping(id: Int64, ws: UnsafePointer[c_void]) -> None:
    logt("ws_on_ping ws: " + String(ws))
    try:
        ws_ping_callbacks_ptr()[][Int(id)]()
    except e:
        pass


fn _ws_on_error(id: Int64, ws: UnsafePointer[c_void], err: StrBoxed) -> None:
    var s = String(StringRef(err.ptr, err.len))
    logt("ws_on_error ws: " + String(ws))
    try:
        ws_error_callbacks_ptr()[][Int(id)](s)
    except e:
        pass
    free_str(err)


fn _ws_on_close(id: Int64, ws: UnsafePointer[c_void]) -> None:
    logt("ws_on_close ws: " + String(ws))
    try:
        ws_close_callbacks_ptr()[][Int(id)]()
    except e:
        pass


fn _ws_on_timer(id: Int64, ws: UnsafePointer[c_void], count: UInt64) -> None:
    logt("ws_on_timer ws: " + String(ws) + " count: " + String(count))
    try:
        ws_timer_callbacks_ptr()[][Int(id)](count)
    except e:
        pass


struct WebSocket:
    var _id: Int
    var _ws: UnsafePointer[c_void]
    var _uri: String
    var _port: Int
    var _path: String

    fn __init__(out self, host: String, port: Int, path: String):
        self._id = Int(idgen_next_id())
        self._ws = UnsafePointer[c_void]()
        self._uri = host
        self._port = port
        self._path = path
        ws_map_ptr()[][self._id] = UnsafePointer[Self].address_of(self)

    fn set_on_open(self: Self, owned on_open: WebSocketOpenCallback) -> None:
        ws_open_callbacks_ptr()[][self._id] = on_open^

    fn set_on_message(
        self: Self, owned on_message: WebSocketMessageCallback
    ) -> None:
        ws_message_callbacks_ptr()[][self._id] = on_message^

    fn set_on_ping(self: Self, owned on_ping: WebSocketPingCallback) -> None:
        ws_ping_callbacks_ptr()[][self._id] = on_ping^

    fn set_on_error(self: Self, owned on_error: WebSocketErrorCallback) -> None:
        ws_error_callbacks_ptr()[][self._id] = on_error^

    fn set_on_close(self: Self, owned on_close: WebSocketCloseCallback) -> None:
        ws_close_callbacks_ptr()[][self._id] = on_close^

    fn set_on_timer(self: Self, owned on_timer: WebSocketTimerCallback) -> None:
        ws_timer_callbacks_ptr()[][self._id] = on_timer^

    fn get_id(self) -> Int:
        return self._id

    fn get_ws(self) -> UnsafePointer[c_void]:
        return self._ws

    fn _set_ws(mut self: Self, ws: UnsafePointer[c_void]) -> None:
        self._ws = ws

    fn run(mut self: Self, rt: MonoioRuntimePtr) -> None:
        logd("WebSocket.run")
        var ret = connect_ws(
            rt,
            self._id,
            self._uri.unsafe_cstr_ptr(),
            self._port,
            self._path.unsafe_cstr_ptr(),
            10,
            _ws_on_open,
            _ws_on_message,
            _ws_on_ping,
            _ws_on_error,
            _ws_on_close,
            _ws_on_timer,
        )
        logd("connect_ws ret: " + String(ret))

    fn send(self: Self, text: String) -> Int:
        if self._ws == UnsafePointer[c_void]():
            logw("ws is not connected")
            return -1
        var ret = ws_send_text(self._ws, text.unsafe_cstr_ptr())
        return Int(ret)
