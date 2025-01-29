from python import Python
from python import PythonObject
from collections import Dict
from memory import UnsafePointer, memcpy
import sys.ffi
import sys
from _ffi import ffi_code


fn get_wrapper[
    Fn: AnyTrivialRegType
](
    f: Fn, ret_type: StringLiteral, *args_types: StringLiteral
) raises -> PythonObject:
    var ctypes = Python.import_module("ctypes")
    var function_pointer = UnsafePointer[Fn].alloc(1)
    function_pointer[0] = f
    var c_function = (ctypes.CFUNCTYPE(ctypes.c_void_p)).from_address(
        Int(function_pointer)
    )

    var py_obj_argtypes = PythonObject([])

    for i in range(args_types.__len__()):
        py_obj_argtypes.append(ctypes.__getattr__(args_types[i]))

    c_function.argtypes = py_obj_argtypes
    c_function.restype = ctypes.__getattr__(ret_type)
    # note: function_pointer is never freed
    return c_function


fn copy_string_to_buffer(s: String, buff: UnsafePointer[ffi.c_char], buff_size: ffi.c_int) -> Int:
    """
    将字符串复制到结果缓冲区中.

    参数:
        s (String): 要复制的字符串
        buff (UnsafePointer[ffi.c_char]): 目标缓冲区指针
        buff_size (ffi.c_int): 目标缓冲区大小

    返回:
        Int: 复制的字符数量.
    """
    var res_bytes = s.unsafe_ptr().bitcast[ffi.c_char]()
    var res_len = len(s)
    
    if res_len >= Int(buff_size):
        res_len = Int(buff_size) - 1  # Leave space for null terminator
    
    memcpy(buff, res_bytes, res_len)
    buff[res_len] = 0  # Null terminator
    
    return res_len


fn _tv_init(
    # p: Int,
    id_ptr: UnsafePointer[ffi.c_char],
    body_ptr: UnsafePointer[ffi.c_char],
    result_buff: UnsafePointer[ffi.c_char],
    result_buff_size: ffi.c_int,
) -> Int:
    var id = String(id_ptr)
    var body = String(body_ptr)
    print("_tv_init: ")
    print("id: " + id)
    print("body: " + body)
    var res = String("OK")
    var res_len = copy_string_to_buffer(res, result_buff, result_buff_size)

    return res_len


fn main() raises:
    # Python.add_to_path("./")
    # var _ffi = Python.import_module("_ffi")
    # var hello = _ffi.hello
    # var tv_init = _ffi.tv_init

    # var mojo_tv_init = get_wrapper(_tv_init, "c_int", "c_int", "c_char_p")
    # var mojo_tv_init = get_wrapper(_tv_init, "c_int", "c_char_p", "c_char_p", "c_char_p", "c_int")
    # _ffi.set_tv_init(mojo_tv_init)

    # https://github.com/titabash/optverse/blob/main/backend-py/app/src/hello.mojo
    # https://github.com/Phelsong/mojo_scratch/blob/main/fastapi.mojo
    # https://github.com/ego/awesome-mojo/blob/main/algorithm/MojoFastAPI.mojo

    # Python fastapi
    var fastapi = Python.import_module("fastapi")
    var uvicorn = Python.import_module("uvicorn")

    var app = fastapi.FastAPI()
    var router = fastapi.APIRouter()

    # tricky part
    var py = Python()
    # var py_code = """lambda: 'Hello Mojo🔥!'"""
    # var py_obj = py.evaluate(py_code)
    # var py_code = """def hello1():
    # return 'OK333'"""
    # var py_obj = py.evaluate(py_code)

    # py.evaluate("print('hello')")
    var _ffi = Python.evaluate(ffi_code(), file=True)

    # print(_ffi)

    var hello = _ffi.hello
    var tv_init = _ffi.tv_init

    var mojo_tv_init = get_wrapper(_tv_init, "c_int", "c_char_p", "c_char_p", "c_char_p", "c_int")
    _ffi.set_tv_init(mojo_tv_init)

    router.add_api_route("/", endpoint=hello, methods=["GET"])
    router.add_api_route("/tv/{id}", endpoint=tv_init, methods=["POST"])

    app.include_router(router)

    print("Start WEB Server")
    uvicorn.run(app, host="0.0.0.0", port=3000)
    print("Done")
