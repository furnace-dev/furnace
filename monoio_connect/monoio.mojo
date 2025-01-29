from .internal.monoio import MonoioRuntimePtr, monoio_sleep_ms, monoio_sleep_ns


@always_inline
fn sleep_ms(rt: MonoioRuntimePtr, duration_ms: UInt64):
    _ = monoio_sleep_ms(rt, duration_ms)


@always_inline
fn sleep_ns(rt: MonoioRuntimePtr, duration_ns: UInt64):
    _ = monoio_sleep_ns(rt, duration_ns)


@always_inline
fn sleep(rt: MonoioRuntimePtr, duration: Float64):
    var duration_ns = Int(duration * 1000000)
    _ = monoio_sleep_ns(rt, duration_ns)
