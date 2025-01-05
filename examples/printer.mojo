@value
struct Printer:
    var data: String

    fn __del__(owned self):
        print(self.data)


fn main():
    var a = Printer("a")
    # var b = Reference[Printer, __mlir_attr.`1: i1`, __lifetime_of(a)](
    #     UnsafePointer.address_of(a).__refitem__()
    # )
    var b = Pointer.address_of(a)

    var c = Printer("c")
    print(b[].data)