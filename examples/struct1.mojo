struct MyStruct1:
    var a: Int
    var b: Int

    fn __init__(out self, a: Int, b: Int):
        self.a = a
        self.b = b


struct MyStruct2[is_mutable: Bool, origin: Origin[is_mutable].type]:
    var m_ptr: Pointer[MyStruct1, origin=origin]

    fn __init__(out self, m_ptr: Pointer[MyStruct1, origin=origin]):
        self.m_ptr = m_ptr

    fn print_a(self):
        print(self.m_ptr[].a)


struct MyStruct3[origin: MutableOrigin]:
    var m_ptr: Pointer[MyStruct1, origin=origin]

    fn __init__(out self, m_ptr: Pointer[MyStruct1, origin=origin]):
        self.m_ptr = m_ptr

    fn incr_a(self):
        self.m_ptr[].a += 1


fn main():
    var s1 = MyStruct1(3, 4)
    var s2 = MyStruct3(Pointer.address_of(s1))

    print(s1.a)
    s2.incr_a()
    print(s1.a)
