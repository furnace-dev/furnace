from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t
from utils import StringRef
from .monoio import MonoioRuntimePtr, StrBoxed, free_str


alias fn_on_open = fn (id: Int64, ws: UnsafePointer[c_void]) -> None

alias fn_on_message = fn (
    id: Int64, ws: UnsafePointer[c_void], msg: StrBoxed
) -> None

alias fn_on_ping = fn (id: Int64, ws: UnsafePointer[c_void]) -> None

alias fn_on_error = fn (
    id: Int64, ws: UnsafePointer[c_void], err: StrBoxed
) -> None

alias fn_on_close = fn (id: Int64, ws: UnsafePointer[c_void]) -> None

alias fn_on_timer = fn (
    id: Int64, ws: UnsafePointer[c_void], count: UInt64
) -> None


alias fn_connect_ws = fn (
    rt: MonoioRuntimePtr,
    id: Int64,
    uri: UnsafePointer[c_char],
    port: UInt16,
    path: UnsafePointer[c_char],
    timer_sec: UInt64,
    on_open: fn_on_open,
    on_message: fn_on_message,
    on_ping: fn_on_ping,
    on_error: fn_on_error,
    on_close: fn_on_close,
    on_timer: fn_on_timer,
) -> Int32

alias fn_connect_ws_no_blocking = fn (
    rt: MonoioRuntimePtr,
    id: Int64,
    uri: UnsafePointer[c_char],
    port: UInt16,
    path: UnsafePointer[c_char],
    timer_sec: UInt64,
    on_open: fn_on_open,
    on_message: fn_on_message,
    on_ping: fn_on_ping,
    on_error: fn_on_error,
    on_close: fn_on_close,
    on_timer: fn_on_timer,
) -> Int32

alias fn_ws_send_text = fn (
    ws: UnsafePointer[c_void], text: UnsafePointer[c_char]
) -> Int32

var _handle: DLHandle = DLHandle(LIBNAME)

var _connect_ws = _handle.get_function[fn_connect_ws]("connect_ws")

var _connect_ws_no_blocking = _handle.get_function[fn_connect_ws_no_blocking](
    "connect_ws_no_blocking"
)

var _ws_send_text = _handle.get_function[fn_ws_send_text]("ws_send_text")


@always_inline
fn connect_ws(
    rt: MonoioRuntimePtr,
    id: Int64,
    uri: UnsafePointer[c_char],
    port: UInt16,
    path: UnsafePointer[c_char],
    timer_sec: UInt64,
    on_open: fn_on_open,
    on_message: fn_on_message,
    on_ping: fn_on_ping,
    on_error: fn_on_error,
    on_close: fn_on_close,
    on_timer: fn_on_timer,
) -> Int32:
    return _connect_ws(
        rt,
        id,
        uri,
        port,
        path,
        timer_sec,
        on_open,
        on_message,
        on_ping,
        on_error,
        on_close,
        on_timer,
    )


@always_inline
fn connect_ws_no_blocking(
    rt: MonoioRuntimePtr,
    id: Int64,
    uri: UnsafePointer[c_char],
    port: UInt16,
    path: UnsafePointer[c_char],
    timer_sec: UInt64,
    on_open: fn_on_open,
    on_message: fn_on_message,
    on_ping: fn_on_ping,
    on_error: fn_on_error,
    on_close: fn_on_close,
    on_timer: fn_on_timer,
) -> Int32:
    return _connect_ws_no_blocking(
        rt,
        id,
        uri,
        port,
        path,
        timer_sec,
        on_open,
        on_message,
        on_ping,
        on_error,
        on_close,
        on_timer,
    )


@always_inline
fn ws_send_text(
    ws: UnsafePointer[c_void], text: UnsafePointer[c_char]
) -> Int32:
    return _ws_send_text(ws, text)
