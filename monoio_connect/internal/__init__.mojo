from sys.ffi import DLHandle, c_char, c_size_t
from sys.param_env import is_defined


alias c_void = UInt8
alias c_int32 = Int32
alias c_uint8 = UInt8
alias c_uint32 = UInt32
alias c_uint16 = UInt16

alias c_char_ptr = UnsafePointer[c_char]
alias c_void_ptr = UnsafePointer[c_void]

alias LIBNAME = "libfurnace_connect.so"


@always_inline("nodebug")
fn is_static_build() -> Bool:
    """
    Returns True if the build is in debug mode.

    Returns:
        Bool: True if the build is in debug mode and False otherwise.
    """

    @parameter
    if is_defined["IS_STATIC_BUILD"]():
        return True
    else:
        return False
