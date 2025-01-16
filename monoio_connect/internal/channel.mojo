from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t, external_call

alias ChannelPtr = UnsafePointer[c_void]

alias fn_create_channel = fn (
    channel_type: c_int32, capacity: c_size_t
) -> ChannelPtr

alias fn_destroy_channel = fn (channel: ChannelPtr) -> None

alias fn_channel_send = fn (
    channel: ChannelPtr, data: UnsafePointer[c_void]
) -> c_int32

alias fn_channel_recv = fn (channel: ChannelPtr) -> UnsafePointer[c_void]

var _handle: DLHandle = DLHandle(LIBNAME)

var _create_channel = _handle.get_function[fn_create_channel]("create_channel")
var _destroy_channel = _handle.get_function[fn_destroy_channel](
    "destroy_channel"
)
var _channel_send = _handle.get_function[fn_channel_send]("channel_send")
var _channel_recv = _handle.get_function[fn_channel_recv]("channel_recv")


@always_inline
fn create_channel(channel_type: c_int32, capacity: c_size_t) -> ChannelPtr:
    @parameter
    if is_static_build():
        return external_call["create_channel", ChannelPtr](
            channel_type, capacity
        )
    else:
        return _create_channel(channel_type, capacity)


@always_inline
fn destroy_channel(channel: ChannelPtr):
    @parameter
    if is_static_build():
        external_call["destroy_channel", NoneType](channel)
    else:
        _destroy_channel(channel)


@always_inline
fn channel_send(channel: ChannelPtr, data: UnsafePointer[c_void]) -> c_int32:
    @parameter
    if is_static_build():
        return external_call["channel_send", c_int32](channel, data)
    else:
        return _channel_send(channel, data)


@always_inline
fn channel_recv(channel: ChannelPtr) -> UnsafePointer[c_void]:
    @parameter
    if is_static_build():
        return external_call["channel_recv", UnsafePointer[c_void]](channel)
    else:
        return _channel_recv(channel)
