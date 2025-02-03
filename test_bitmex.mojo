from testing import assert_equal
from small_time.small_time import strptime, SmallTime
from small_time.time_zone import TimeZone
from toolbox import to_unix_timestamp, to_unix_timestamp_microseconds


fn test_bitmex_timestamp() raises:
    var timestamp = "2025-02-03T01:39:21.727Z"
    var datetime = strptime(timestamp, "%Y-%m-%dT%H:%M:%S.%fZ")
    print(datetime)
    print(to_unix_timestamp_microseconds(datetime))
    assert_equal(to_unix_timestamp_microseconds(datetime), 1738546761000000)
    assert_equal(to_unix_timestamp(datetime), 1738546761)


fn main() raises:
    test_bitmex_timestamp()
