from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t, external_call
from utils import StringRef


@value
@register_passable("trivial")
struct SliceBoxedUInt8(Stringable):
    var ptr: UnsafePointer[UInt8]
    var len: c_size_t

    fn __init__(out self, s: String):
        self.ptr = UnsafePointer[UInt8].alloc(len(s))
        self.len = len(s)
        memcpy(dest=self.ptr, src=s.unsafe_ptr(), count=len(s))

    fn __str__(self) -> String:
        return String(StringRef(self.ptr, int(self.len)))


alias StrBoxed = SliceBoxedUInt8

alias MonoioRuntimePtr = UnsafePointer[c_void]

alias fn_create_monoio_runtime = fn () -> MonoioRuntimePtr

alias fn_destroy_monoio_runtime = fn (rt: MonoioRuntimePtr) -> None

# task entry
alias TaskEntryArg = UnsafePointer[c_void]
alias fn_task_entry = fn (data: TaskEntryArg) -> Int32

alias fn_destroy_client_builder = fn (
    client_builder: UnsafePointer[c_void]
) -> None

alias fn_block_on_runtime = fn (
    rt: MonoioRuntimePtr, f: fn_task_entry, arg: TaskEntryArg
) -> None

alias fn_spawn_task_on_runtime = fn (
    rt: MonoioRuntimePtr, f: fn_task_entry, arg: TaskEntryArg
) -> None

alias fn_monoio_sleep_ms = fn (
    rt: MonoioRuntimePtr, duration_ms: UInt64
) -> None

alias fn_monoio_sleep_ns = fn (
    rt: MonoioRuntimePtr, duration_ns: UInt64
) -> None

alias fn_bind_to_cpu_set = fn (core_id: UInt32) -> None

alias fn_free_str = fn (s: StrBoxed) -> None

var _handle: DLHandle = DLHandle(LIBNAME)

var _create_monoio_runtime = _handle.get_function[fn_create_monoio_runtime](
    "create_monoio_runtime"
)

var _destroy_monoio_runtime = _handle.get_function[fn_destroy_monoio_runtime](
    "destroy_monoio_runtime"
)

var _destroy_client_builder = _handle.get_function[fn_destroy_client_builder](
    "destroy_client_builder"
)

var _block_on_runtime = _handle.get_function[fn_block_on_runtime](
    "block_on_runtime"
)

var _spawn_task_on_runtime = _handle.get_function[fn_spawn_task_on_runtime](
    "spawn_task_on_runtime"
)

var _monoio_sleep_ms = _handle.get_function[fn_monoio_sleep_ms](
    "monoio_sleep_ms"
)

var _monoio_sleep_ns = _handle.get_function[fn_monoio_sleep_ns](
    "monoio_sleep_ns"
)

var _bind_to_cpu_set = _handle.get_function[fn_bind_to_cpu_set](
    "bind_to_cpu_set"
)

var _free_str = _handle.get_function[fn_free_str]("free_str")


@always_inline
fn create_monoio_runtime() -> MonoioRuntimePtr:
    @parameter
    if is_static_build():
        return external_call["create_monoio_runtime", MonoioRuntimePtr]()
    else:
        return _create_monoio_runtime()


@always_inline
fn destroy_monoio_runtime(rt: MonoioRuntimePtr) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_monoio_runtime", NoneType](rt)
    else:
        _destroy_monoio_runtime(rt)


@always_inline
fn destroy_client_builder(client_builder: UnsafePointer[c_void]) -> None:
    @parameter
    if is_static_build():
        external_call["destroy_client_builder", NoneType](client_builder)
    else:
        _destroy_client_builder(client_builder)


@always_inline
fn block_on_runtime(
    rt: MonoioRuntimePtr, f: fn_task_entry, arg: TaskEntryArg
) -> None:
    @parameter
    if is_static_build():
        external_call["block_on_runtime", NoneType](rt, f, arg)
    else:
        _block_on_runtime(rt, f, arg)


@always_inline
fn spawn_task_on_runtime(
    rt: MonoioRuntimePtr, f: fn_task_entry, arg: TaskEntryArg
) -> None:
    @parameter
    if is_static_build():
        external_call["spawn_task_on_runtime", NoneType](rt, f, arg)
    else:
        _spawn_task_on_runtime(rt, f, arg)


@always_inline
fn monoio_sleep_ms(rt: MonoioRuntimePtr, duration_ms: UInt64) -> None:
    @parameter
    if is_static_build():
        external_call["monoio_sleep_ms", NoneType](rt, duration_ms)
    else:
        _monoio_sleep_ms(rt, duration_ms)


@always_inline
fn monoio_sleep_ns(rt: MonoioRuntimePtr, duration_ns: UInt64) -> None:
    @parameter
    if is_static_build():
        external_call["monoio_sleep_ns", NoneType](rt, duration_ns)
    else:
        _monoio_sleep_ns(rt, duration_ns)


@always_inline
fn bind_to_cpu_set(core_id: UInt32) -> None:
    @parameter
    if is_static_build():
        external_call["bind_to_cpu_set", NoneType](core_id)
    else:
        _bind_to_cpu_set(core_id)


@always_inline
fn free_str(s: StrBoxed) -> None:
    @parameter
    if is_static_build():
        external_call["free_str", NoneType](s)
    else:
        _free_str(s)
