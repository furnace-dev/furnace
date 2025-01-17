from memory import UnsafePointer, memcpy, stack_allocation
from utils import StringRef
import .internal.nanoid as nanoid_internal


@always_inline
fn nanoid() -> String:
    var buf = stack_allocation[32, UInt8]()
    var len = nanoid_internal.nanoid(buf)
    return String(StringRef(buf, len))
