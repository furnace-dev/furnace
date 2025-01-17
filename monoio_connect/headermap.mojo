from memory import UnsafePointer, stack_allocation
from utils import StringRef
from .internal.httpclient import (
    HeaderMapPtr,
    create_header_map,
    destroy_header_map,
    header_map_get,
    header_map_set,
)


struct HeaderMap(Movable):
    var _ptr: HeaderMapPtr

    fn __init__(out self):
        self._ptr = create_header_map()

    fn __moveinit__(out self, owned other: Self):
        self._ptr = other._ptr
        other._ptr = HeaderMapPtr()

    fn __del__(owned self):
        if self._ptr:
            destroy_header_map(self._ptr)

    fn get[max_value_size: Int = 512](self, key: String) -> String:
        var buf = stack_allocation[max_value_size, Int8]()
        var size = header_map_get(self._ptr, key.unsafe_cstr_ptr(), buf)
        if size == 0:
            return ""
        else:
            return String(StringRef(buf, size))

    @always_inline
    fn set(self, key: String, value: String):
        header_map_set(
            self._ptr, key.unsafe_cstr_ptr(), value.unsafe_cstr_ptr()
        )
