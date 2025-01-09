from testing import assert_equal, assert_true
# from small_time import *
# from small_time.small_time import from_timestamp, now


fn test_small_time_yymmdd() raises:
    # expiry = 1593763200000
    # print(yymmdd(1717392000, ""))
    # 2020-07-03 16:00:00

    # var p1 = from_timestamp(1593763200000)
    # assert_equal(str(p1), "2020-07-03T16:00:00.000000+08:00")
    # assert_equal(p1.format("YYMMDD"), "200703")
    # var p2 = from_timestamp(1593763200)
    # assert_equal(p2.format("YYMMDD"), "200703")
    pass


fn test_small_time_iso8601() raises:
    # var p1 = from_timestamp(1593763200000)
    pass
    # iso8601
    # utc = datetime.datetime.fromtimestamp(timestamp // 1000, datetime.timezone.utc)
    #         return utc.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-6] + "{:03d}".format(int(timestamp) % 1000) + 'Z'
    # assert_equal(p1.isoformat(), "2020-07-03T16:00:00.000000+08:00")


fn test_now() raises:
    # var p1 = now()
    pass
    # var s = p1.format("YYYY-MM-DD HH:mm:ss.SSS")
    # assert_true("20" in s)
    # assert_equal(s, "2024-12-18 08:53:36.427411")
