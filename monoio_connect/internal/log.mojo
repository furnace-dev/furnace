from memory import UnsafePointer, memcpy
from builtin._location import __call_location
from sys.ffi import DLHandle, c_char, c_size_t, external_call


alias LoggerPtr = UnsafePointer[c_void]

alias fn_init_logger = fn (
    level: c_uint8,
    time_format: UnsafePointer[c_char],
    path: UnsafePointer[c_char],
) -> LoggerPtr

alias fn_destroy_logger = fn (logger: LoggerPtr) -> None

alias fn_test_log = fn () -> None


alias fn_log_max_level = fn () -> c_uint8

alias fn_log = fn (
    level: c_uint8,
    file: UnsafePointer[c_char],
    line: c_uint32,
    col: c_uint32,
    msg: UnsafePointer[c_char],
)

var _handle: DLHandle = DLHandle(LIBNAME)

var _init_logger = _handle.get_function[fn_init_logger]("init_logger")
var _destroy_logger = _handle.get_function[fn_destroy_logger]("destroy_logger")

var _test_log = _handle.get_function[fn_test_log]("test_log")

var _log = _handle.get_function[fn_log]("log")
var _log_max_level = _handle.get_function[fn_log_max_level]("log_max_level")


@always_inline
fn init_logger(
    level: c_uint8,
    time_format: UnsafePointer[c_char],
    path: UnsafePointer[c_char],
) -> LoggerPtr:
    @parameter
    if is_static_build():
        return external_call["init_logger", LoggerPtr](level, time_format, path)
    else:
        return _init_logger(level, time_format, path)


@always_inline
fn destroy_logger(logger: LoggerPtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_logger", NoneType](logger)
    else:
        return _destroy_logger(logger)


@always_inline
fn test_log() -> None:
    @parameter
    if is_static_build():
        external_call["test_log", NoneType]()
    else:
        _test_log()


@always_inline
fn log_max_level() -> c_uint8:
    @parameter
    if is_static_build():
        return external_call["log_max_level", c_uint8]()
    else:
        return _log_max_level()


@always_inline
fn log(
    level: c_uint8,
    file: UnsafePointer[c_char],
    line: c_uint32,
    col: c_uint32,
    msg: UnsafePointer[c_char],
) -> None:
    @parameter
    if is_static_build():
        external_call["log", NoneType](level, file, line, col, msg)
    else:
        _log(level, file, line, col, msg)
