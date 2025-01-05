from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t
from utils import StringRef

alias fn_idgen_set_options = fn (
    worker_id: UInt32, worker_id_bit_length: UInt8, seq_bit_length: UInt8
) -> None


alias fn_idgen_set_worker_id = fn (worker_id: UInt32) -> None

alias fn_idgen_next_id = fn () -> Int64

var _handle: DLHandle = DLHandle(LIBNAME)


var _idgen_set_options = _handle.get_function[fn_idgen_set_options](
    "idgen_set_options"
)

var _idgen_set_worker_id = _handle.get_function[fn_idgen_set_worker_id](
    "idgen_set_worker_id"
)

var _idgen_next_id = _handle.get_function[fn_idgen_next_id]("idgen_next_id")


@always_inline
fn idgen_set_options(
    worker_id: UInt32, worker_id_bit_length: UInt8, seq_bit_length: UInt8
) -> None:
    _idgen_set_options(worker_id, worker_id_bit_length, seq_bit_length)


fn idgen_set_worker_id(worker_id: UInt32) -> None:
    _idgen_set_worker_id(worker_id)


fn idgen_next_id() -> Int64:
    return _idgen_next_id()
