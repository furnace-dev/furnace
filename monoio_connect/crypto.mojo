from memory import UnsafePointer, memcpy, stack_allocation
from sys.ffi import DLHandle, c_char, c_size_t
from utils import StringRef
import .internal.crypto as crypto_internal


@always_inline
fn compute_sha512_hex(content: String) -> String:
    alias buf_size = 128
    var buf = stack_allocation[buf_size, UInt8]()
    var n = crypto_internal.compute_sha512_hex(
        content.unsafe_cstr_ptr(), buf, buf_size
    )
    return String(StringRef(buf, n))


@always_inline
fn compute_hmac_sha512_hex(
    content: String,
    secret: String,
) -> String:
    alias buf_size = 128
    var buf = stack_allocation[buf_size, UInt8]()
    var n = crypto_internal.compute_hmac_sha512_hex(
        content.unsafe_cstr_ptr(),
        secret.unsafe_cstr_ptr(),
        buf,
        buf_size,
    )
    return String(StringRef(buf, n))


@always_inline
fn compute_sha256_hex(content: String) -> String:
    alias buf_size = 128
    var buf = stack_allocation[buf_size, UInt8]()
    var n = crypto_internal.compute_sha256_hex(
        content.unsafe_cstr_ptr(), buf, buf_size
    )
    return String(StringRef(buf, n))


@always_inline
fn compute_hmac_sha256_hex(
    content: String,
    secret: String,
) -> String:
    alias buf_size = 128
    var buf = stack_allocation[buf_size, UInt8]()
    var n = crypto_internal.compute_hmac_sha256_hex(
        content.unsafe_cstr_ptr(),
        secret.unsafe_cstr_ptr(),
        buf,
        buf_size,
    )
    return String(StringRef(buf, n))
