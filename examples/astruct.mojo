from memory import UnsafePointer
from testing import assert_equal


struct A:
    var data: UnsafePointer[Int]

    fn __init__(out self):
        self.data = UnsafePointer[Int].alloc(1)
        self.data.init_pointee_copy(1)

    fn __del__(owned self):
        self.data.free()


# struct A1:
#     var _data: UnsafePointer[UInt8]

#     fn data(ref[_] self) -> UnsafePointer[UInt8, __origin_of(self)]:
#         return self._data


fn test_destruct() raises:
    a = A()
    assert_equal(a.data[0], 1)
    # _ = a.data


fn main() raises:
    test_destruct()
