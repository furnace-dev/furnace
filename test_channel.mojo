from testing import assert_equal, assert_true
from memory import UnsafePointer
from monoio_connect import *


fn test_channel_raw() raises:
    var c = Channel()

    var data = UnsafePointer[UInt8].alloc(1)
    data[] = 100
    var ok = c.send(data)
    assert_equal(ok, 0)
    var r = c.recv_raw()
    assert_equal(r[], 100)
    var r1 = c.recv_raw()
    assert_equal(int(r1), 0)
    assert_equal(r1, UnsafePointer[UInt8]())
    r.free()

    _ = c^


@value
struct TestData:
    var a: Int
    var s: String

    fn __init__(out self, a: Int, s: String):
        print("__init__")
        self.a = a
        self.s = s

    fn __del__(owned self):
        print("__del__")


fn test_channel() raises:
    var c = Channel()

    var data = UnsafePointer[TestData].alloc(1)
    __get_address_as_uninit_lvalue(data.address) = TestData(a=100, s="hello")
    var ok = c.send(data)
    assert_equal(ok, 0)
    var r = c.recv[TestData]()
    assert_true(r)
    var data_ = r.take()
    assert_equal(data_[].a, 100)
    assert_equal(data_[].s, "hello")
    data_.destroy_pointee()
    data_.free()

    var data2 = c.recv[TestData]()
    assert_true(not data2)

    _ = c^


fn test_channel_move() raises:
    var c = Channel()

    var data = TestData(a=100, s="hello")
    var ok = c.send(data)
    assert_equal(ok, 0)
    var r = c.recv[TestData]()
    assert_true(r)
    var data_ = r.take()
    assert_equal(data_[].a, 100)
    assert_equal(data_[].s, "hello")
    data_.destroy_pointee()
    data_.free()

    var data2 = c.recv[TestData]()
    assert_true(not data2)

    _ = c^
