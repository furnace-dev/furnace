from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t, external_call


alias fn_fixed12_mul = fn (a: Int64, b: Int64) -> Int64

alias fn_fixed12_truediv = fn (a: Int64, b: Int64) -> Int64

var _handle: DLHandle = DLHandle(LIBNAME)

var _fixed12_mul = _handle.get_function[fn_fixed12_mul]("fixed12_mul")
var _fixed12_truediv = _handle.get_function[fn_fixed12_truediv](
    "fixed12_truediv"
)


@always_inline
fn fixed12_mul(a: Int64, b: Int64) -> Int64:
    @parameter
    if is_static_build():
        return external_call["fixed12_mul", Int64](a, b)
    else:
        return _fixed12_mul(a, b)


@always_inline
fn fixed12_truediv(a: Int64, b: Int64) -> Int64:
    @parameter
    if is_static_build():
        return external_call["fixed12_truediv", Int64](a, b)
    else:
        return _fixed12_truediv(a, b)
