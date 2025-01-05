from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t


# [`NS_PER_SEC`]  The number of nanoseconds in each second is equal to one billion nanoseconds.
alias NS_PER_SEC: Int64 = 1000000000

# [`INIT_CALIBRATE_NANOS`] The default initial calibration sampling duration is 300 milliseconds.
alias INIT_CALIBRATE_NANOS: Int64 = 300000000

# [`CALIBRATE_INTERVAL_NANOS`] The default clock calibration period is 3 seconds.
alias CALIBRATE_INTERVAL_NANOS: Int64 = 3000000000

alias fn_tscns_init = fn (
    init_calibrate_ns: Int64, calibrate_interval_ns: Int64
) -> None

alias fn_tscns_calibrate = fn () -> None

alias fn_tscns_read_nanos = fn () -> Int64

var _handle: DLHandle = DLHandle(LIBNAME)

var _tscns_init = _handle.get_function[fn_tscns_init]("tscns_init")

var _tscns_calibrate = _handle.get_function[fn_tscns_calibrate](
    "tscns_calibrate"
)

var _tscns_read_nanos = _handle.get_function[fn_tscns_read_nanos](
    "tscns_read_nanos"
)


@always_inline
fn tscns_init(init_calibrate_ns: Int64, calibrate_interval_ns: Int64) -> None:
    _tscns_init(init_calibrate_ns, calibrate_interval_ns)


@always_inline
fn tscns_calibrate() -> None:
    _tscns_calibrate()


@always_inline
fn tscns_read_nanos() -> Int64:
    return _tscns_read_nanos()
