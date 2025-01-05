from ctypes import CFUNCTYPE, c_int


Ft = CFUNCTYPE(c_int, c_int, c_int)


def entry_point(ptr_to_function):
    function_pointer = Ft(ptr_to_function)
    result = function_pointer(5000, 2)
    return result