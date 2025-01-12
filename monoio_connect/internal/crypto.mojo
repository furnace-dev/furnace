from memory import UnsafePointer, memcpy, stack_allocation
from sys.ffi import DLHandle, c_char, c_size_t
from utils import StringRef

alias fn_compute_sha512_hex = fn (
    content: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t


alias fn_compute_hmac_sha512_hex = fn (
    content: c_char_ptr,
    secret: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t

alias fn_compute_sha256_hex = fn (
    content: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t

alias fn_compute_hmac_sha256_hex = fn (
    content: c_char_ptr,
    secret: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t

var _handle: DLHandle = DLHandle(LIBNAME)

var _compute_sha512_hex = _handle.get_function[fn_compute_sha512_hex](
    "compute_sha512_hex"
)

var _compute_hmac_sha512_hex = _handle.get_function[fn_compute_hmac_sha512_hex](
    "compute_hmac_sha512_hex"
)

var _compute_sha256_hex = _handle.get_function[fn_compute_sha256_hex](
    "compute_sha256_hex"
)

var _compute_hmac_sha256_hex = _handle.get_function[fn_compute_hmac_sha256_hex](
    "compute_hmac_sha256_hex"
)


@always_inline
fn compute_sha512_hex(
    content: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t:
    return _compute_sha512_hex(content, result, len)


@always_inline
fn compute_hmac_sha512_hex(
    content: c_char_ptr,
    secret: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t:
    return _compute_hmac_sha512_hex(content, secret, result, len)


@always_inline
fn compute_sha256_hex(
    content: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t:
    return _compute_sha256_hex(content, result, len)


@always_inline
fn compute_hmac_sha256_hex(
    content: c_char_ptr,
    secret: c_char_ptr,
    result: UnsafePointer[c_void],
    len: c_size_t,
) -> c_size_t:
    return _compute_hmac_sha256_hex(content, secret, result, len)
