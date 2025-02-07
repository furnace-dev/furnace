from sys.ffi import DLHandle, c_char, c_size_t
from memory import UnsafePointer
from sys.param_env import is_defined
from sys import os_is_macos
from .monoio import (
    StrBoxed,
    bind_to_cpu_set,
    create_monoio_runtime,
    free_str,
    destroy_monoio_runtime,
    block_on_runtime,
    spawn_task_on_runtime,
    TaskEntryArg,
)


alias c_void = UInt8
alias c_int32 = Int32
alias c_uint8 = UInt8
alias c_uint32 = UInt32
alias c_uint16 = UInt16

alias c_char_ptr = UnsafePointer[c_char]
alias c_void_ptr = UnsafePointer[c_void]


# os platform:
fn get_libname() -> StringLiteral:
    @parameter
    if os_is_macos():
        return "bin/libfurnace_connect.dylib"
    else:
        return "bin/libfurnace_connect.so"

alias LIBNAME = get_libname()


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
