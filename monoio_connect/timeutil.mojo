import time.time


@always_inline
fn now_ns() -> Int:
    return time._gettime_as_nsec_unix(time._CLOCK_REALTIME)


@always_inline
fn now_ms() -> Int:
    return Int(now_ns() / 1_000_000)