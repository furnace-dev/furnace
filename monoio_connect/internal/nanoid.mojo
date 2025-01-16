from memory import UnsafePointer
from sys.ffi import DLHandle, c_char, c_size_t, external_call


alias fn_nanoid = fn (result: UnsafePointer[UInt8]) -> c_size_t

var _handle: DLHandle = DLHandle(LIBNAME)

var _nanoid = _handle.get_function[fn_nanoid]("nanoid")


@always_inline
fn nanoid(result: UnsafePointer[UInt8]) -> c_size_t:
    @parameter
    if is_static_build():
        return external_call["nanoid", c_size_t](result)
    else:
        return _nanoid(result)
