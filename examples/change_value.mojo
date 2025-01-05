struct A:
    var val: Int

    fn __init__(out self, val: Int):
        self.val = val


def print_value[
    is_mutable: Bool, //, origin: Origin[is_mutable].type
](p: Pointer[A, origin=origin]):
    print(p[].val)


def change_value[origin: MutableOrigin](p: Pointer[A, origin=origin]):
    p[] = 15


def print_value_v0(p: A):
    print(p.val) 

def change_value_v0(mut p: A): # Gives error ofc as a_instance is not in scope. What should go inside origin_of?
    p = 15


def main():
    var a_instance = A(12)
    var ref_a = Pointer.address_of(a_instance)
    print_value(ref_a)
    change_value(ref_a)
    ref_a[] = 15
