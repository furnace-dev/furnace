from memory import UnsafePointer, memcpy
from sys.param_env import is_defined
from sys.ffi import DLHandle, c_char, c_size_t
from builtin._location import __call_location
from small_time.small_time import now
# from libc.unistd import gettid
import .internal.log as internal_log


@value
@register_passable("trivial")
struct LogLevel(Stringable):
    var _value: UInt8

    alias Error = LogLevel(1)
    alias Warn = LogLevel(2)
    alias Info = LogLevel(3)
    alias Debug = LogLevel(4)
    alias Trace = LogLevel(5)

    fn __init__(out self, value: UInt8):
        self._value = value

    fn __eq__(self, other: LogLevel) -> Bool:
        return self._value == other._value
    
    fn __lt__(self, other: LogLevel) -> Bool:
        return self._value < other._value

    fn __le__(self, other: LogLevel) -> Bool:
        return self._value <= other._value

    fn __gt__(self, other: LogLevel) -> Bool:
        return self._value > other._value
    
    fn __ge__(self, other: LogLevel) -> Bool:
        return self._value >= other._value

    fn __str__(self) -> String:
        if self == LogLevel.Error:
            return "ERROR"
        elif self == LogLevel.Warn:
            return "WARN"
        elif self == LogLevel.Info:
            return "INFO"
        elif self == LogLevel.Debug:
            return "DEBUG"
        elif self == LogLevel.Trace:
            return "TRACE"
        else:
            return "UNKNOWN"


@always_inline
fn init_logger(
    level: LogLevel, time_format: String, path: String
) -> internal_log.LoggerPtr:
    return internal_log.init_logger(
        level._value, time_format.unsafe_cstr_ptr(), path.unsafe_cstr_ptr()
    )

@always_inline
fn destroy_logger(logger: internal_log.LoggerPtr) -> None:
    internal_log.destroy_logger(logger)

@always_inline
fn log_max_level() -> LogLevel:
    return LogLevel(internal_log.log_max_level())

@always_inline
fn log(
    level: LogLevel, file: String, line: UInt32, col: UInt32, msg: String
) -> None:
    internal_log.log(
        level._value, file.unsafe_cstr_ptr(), line, col, msg.unsafe_cstr_ptr()
    )

@always_inline
fn extract_filename_from_path(file_path: String) -> String:
    try:
        return file_path.split("/")[-1]
    except e:
        return file_path

@always_inline
fn logt(s: String) -> None:
    var call_loc = __call_location()
    var file_name = extract_filename_from_path(String(call_loc.file_name))
    @parameter
    if is_debug_mode():
        if log_max_level() >= LogLevel.Trace:
            log_console(LogLevel.Trace, file_name, call_loc.line, 1, s)
    else:
        log(LogLevel.Trace, file_name, call_loc.line, 1, s)

@always_inline
fn logd(s: String) -> None:
    var call_loc = __call_location()
    var file_name = extract_filename_from_path(String(call_loc.file_name))
    @parameter
    if is_debug_mode():
        if log_max_level() >= LogLevel.Debug:
            log_console(LogLevel.Debug, file_name, call_loc.line, 1, s)
    else:
        log(LogLevel.Debug, file_name, call_loc.line, 1, s)

@always_inline
fn logi(s: String) -> None:
    var call_loc = __call_location()
    var file_name = extract_filename_from_path(String(call_loc.file_name))
    @parameter
    if is_debug_mode():
        if log_max_level() >= LogLevel.Info:
            log_console(LogLevel.Info, file_name, call_loc.line, 1, s)
    else:
        log(LogLevel.Info, file_name, call_loc.line, 1, s)

@always_inline
fn logw(s: String) -> None:
    var call_loc = __call_location()
    var file_name = extract_filename_from_path(String(call_loc.file_name))
    @parameter
    if is_debug_mode():
        if log_max_level() >= LogLevel.Warn:
            log_console(LogLevel.Warn, file_name, call_loc.line, 1, s)
    else:
        log(LogLevel.Warn, file_name, call_loc.line, 1, s)

@always_inline
fn loge(s: String) -> None:
    var call_loc = __call_location()
    var file_name = extract_filename_from_path(String(call_loc.file_name))
    @parameter
    if is_debug_mode():
        if log_max_level() >= LogLevel.Error:
            log_console(LogLevel.Error, file_name, call_loc.line, 1, s)
    else:
        log(LogLevel.Error, file_name, call_loc.line, 1, s)

@always_inline
fn log_console(
    level: LogLevel, file_name: String, line: UInt32, col: UInt32, s: String
) -> None:
    try:
        # 2025-01-05 15:36:04.645534|Info|th=1372098|monoio-connect-demo.mojo:468|hello
        # 2025-01-05 15:32:56.991245 0ms DEBUG  [monoio-connect/src/log.rs:88] Hello world!
        var t = now()
        # var tid = gettid()
        var text = t.format("YYYY-MM-DD HH:mm:ss.SSSSSS")
            + " 0ms " + str(level) #+ " th="
            # + str(tid)
            + " ["
            + file_name
            + ":"
            + str(line)
            + "] "
            + str(s)
        print(text)
    except:
        print(str(level) + " error")

@always_inline("nodebug")
fn is_debug_mode() -> Bool:
    """
    Returns True if the build is in debug mode.

    Returns:
        Bool: True if the build is in debug mode and False otherwise.
    """

    @parameter
    if is_defined["DEBUG_MODE"]():
        return True
    else:
        return False
