from testing import assert_equal, assert_true
from small_time.small_time import from_timestamp, now


fn test_small_time_yymmdd() raises:
    # expiry = 1593763200000
    # print(yymmdd(1717392000, ""))
    # 2020-07-03 16:00:00

    var p1 = from_timestamp(1593763200000)
    if "08:00" in String(p1):
        assert_equal(String(p1), "2020-07-03T16:00:00.000000+08:00")
    assert_equal(p1.format("YYMMDD"), "200703")
    var p2 = from_timestamp(1593763200)
    assert_equal(p2.format("YYMMDD"), "200703")


fn test_small_time_iso8601() raises:
    var p1 = from_timestamp(1593763200000)
    if "08:00" in p1.isoformat():
        assert_equal(p1.isoformat(), "2020-07-03T16:00:00.000000+08:00")


fn test_now() raises:
    var p1 = now()
    var s = p1.format("YYYY-MM-DD HH:mm:ss.SSS")
    assert_true("20" in s)


fn main() raises:
    var t = now(utc=False)
    var s = t.format("YYYY-MM-DD HH:mm:ss.SSSSSS")
    print(s)
