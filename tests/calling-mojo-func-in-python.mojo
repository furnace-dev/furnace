# https://github.com/rd4com/mojo-learning/blob/main/tutorials/calling-mojo-functions-in-python.md
from python import Python
from python import PythonObject
from memory import UnsafePointer


fn get_wrapper[Fn: AnyTrivialRegType](f: Fn, ret_type: StringLiteral, *args_types: StringLiteral) raises -> PythonObject:
    var ctypes = Python.import_module("ctypes")
    var tmp_ = UnsafePointer[Fn].alloc(1)
    tmp_[0] = f
    var tmp = (ctypes.CFUNCTYPE(ctypes.c_void_p)).from_address(Int(tmp_))

    var py_obj_argtypes = PythonObject([])

    for i in range(args_types.__len__()):
        py_obj_argtypes.append(ctypes.__getattr__(args_types[i]))
    tmp.argtypes = py_obj_argtypes
    tmp.restype = ctypes.__getattr__(ret_type)
    #note: tmp_ is never freed
    return tmp


fn main() raises:
    Python.add_to_path("./")
    var py_mymodule = Python.import_module("calling-mojo-func-in-python-py")

    fn mojo_print(p: Int) -> Int:
        print(p)
        return p+1
    
    var w = get_wrapper(mojo_print, "c_int", "c_int")
    
    py_mymodule.call_mojo_print(w, 1001)

    fn m_sum(arg: UnsafePointer[Float64], size: Int) -> Float64:
        var total: Float64 = 0.0
        for i in range(size):
            total += arg.load(i)
        return total
    
    var w2 = get_wrapper(m_sum, "c_double", "c_void_p", "c_int")
    py_mymodule.call_sum(w2)