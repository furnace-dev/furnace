from python import Python
from memory import UnsafePointer


# https://gist.github.com/richardkiss/4f1fc7e948ddb7e8dba1e9a907662073

alias Ft = fn(Int, Int) -> Int


fn fn_ptr_as_int64(f: Ft) -> Int64:
    """Recast `f` to `Int64`."""
    var fcp = f
    return UnsafePointer[Ft].address_of(fcp).bitcast[Int64]()[0]


fn mojo_leaf(v: Int, w: Int) -> Int:
    return 2001 + v * w


fn main() raises:
    var fn_ptr = fn_ptr_as_int64(mojo_leaf)
    var ffi = Python.import_module("ffi")
    var entry_point = ffi.entry_point
    print(entry_point(fn_ptr))
    # print(ffi.entry_point(fn_ptr))