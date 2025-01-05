from sys.ffi import DLHandle, c_char, c_size_t


alias c_void = UInt8
alias c_int32 = Int32
alias c_uint8 = UInt8
alias c_uint32 = UInt32
alias c_uint16 = UInt16

alias c_char_ptr = UnsafePointer[c_char]
alias c_void_ptr = UnsafePointer[c_void]

alias LIBNAME = "libfurnace_connect.so"
