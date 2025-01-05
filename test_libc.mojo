from testing import assert_equal, assert_true
from libc.unistd import *


fn test_getpid() raises:
    var pid = getpid()
    assert_true(pid > 0)


fn test_getppid() raises:
    var ppid = getppid()
    assert_true(ppid > 0)


fn test_getuid() raises:
    var uid = getuid()
    assert_true(uid >= 0)


fn test_geteuid() raises:
    var euid = geteuid()
    assert_true(euid >= 0)


fn test_gettid() raises:
    var tid = gettid()
    assert_true(tid > 0)
