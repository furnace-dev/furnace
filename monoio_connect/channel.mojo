from collections import Optional
from .internal.channel import *


struct Channel(Movable):
    """
    A channel is a communication mechanism that allows data to be sent across different threads in a single process.
    """

    var _ptr: ChannelPtr

    fn __init__(out self, capacity: Int = 1024):
        """Initializes a new Channel with a specified capacity."""
        self._ptr = create_channel(2, capacity)

    fn __moveinit__(out self, owned other: Self):
        """Moves ownership of the Channel from another Channel object."""
        self._ptr = other._ptr
        other._ptr = ChannelPtr()

    fn __del__(owned self):
        """Destroys the Channel."""
        if not self._ptr:
            return
        destroy_channel(self._ptr)

    @always_inline
    fn send[T: AnyType](self, data: UnsafePointer[T]) -> Int:
        """Sends data of type T through the channel.

        Args:
            data: A pointer to the data to be sent.

        Returns:
            An integer status code indicating success (0) or failure.
        """
        var data_ = data.bitcast[UInt8]()
        return self.send_raw(data_)

    @always_inline
    fn send[T: Movable](self, owned data: T) -> Int:
        """Sends owned data of type T through the channel.

        Args:
            data: The data to be sent, which is owned by the caller.

        Returns:
            An integer status code indicating success (0) or failure.
        """
        var data_ = UnsafePointer[T].alloc(1)
        __get_address_as_uninit_lvalue(data_.address) = data^
        return self.send_raw(data_.bitcast[UInt8]())

    @always_inline
    fn recv[T: AnyType](self) -> Optional[UnsafePointer[T]]:
        """Receives data of type T from the channel.

        Returns:
            An optional pointer to the received data, or None if no data is available.
        """
        var data = self.recv_raw()
        if data == UnsafePointer[UInt8]():
            return None
        else:
            var data_ = UnsafePointer[T]()
            data_ = data.bitcast[T]()
            return Optional(data_)

    @always_inline
    fn send_raw(self, data: UnsafePointer[UInt8]) -> Int:
        """Sends raw data through the channel.

        Args:
            data: A pointer to the raw data to be sent.

        Returns:
            An integer status code indicating success (0) or failure.
        """
        return int(channel_send(self._ptr, data))

    @always_inline
    fn recv_raw(self) -> UnsafePointer[UInt8]:
        """Receives raw data from the channel.

        Returns:
            A pointer to the received raw data.
        """
        return channel_recv(self._ptr)
