from small_time.small_time import strptime, SmallTime
from small_time.time_zone import TimeZone


fn to_utc(t: SmallTime) -> SmallTime:
    var tz = t.tz
    var offset = tz.offset
    var utc_hour = t.hour - (offset // 3600)
    var utc_minute = t.minute - ((offset % 3600) // 60)
    var utc_second = t.second - (offset % 60)
    return SmallTime(
        t.year,
        t.month,
        t.day,
        utc_hour,
        utc_minute,
        utc_second,
        t.microsecond,
        TimeZone(),
    )


fn to_unix_timestamp_microseconds(t: SmallTime) -> Int:
    """Convert SmallTime to Unix microseconds."""
    var utc_time = to_utc(t)
    var epoch_start = SmallTime(1970, 1, 1, 0, 0, 0, 0, TimeZone())
    var delta_seconds = utc_time - epoch_start
    return delta_seconds._to_microseconds()


fn to_unix_timestamp(t: SmallTime) -> Int:
    var utc_time = to_utc(t)
    var epoch_start = SmallTime(1970, 1, 1, 0, 0, 0, 0, TimeZone())
    var delta_seconds = utc_time - epoch_start
    return int(delta_seconds.total_seconds())
