from benchmark import Unit, keep, run
from time import sleep, perf_counter_ns
from time.time import _gettime_as_nsec_unix
from monoio_connect import *


fn bench_perf_counter_ns():
    var result = perf_counter_ns()
    keep(result)


alias _CLOCK_REALTIME_COARSE = 5


fn bench_perf_counter_ns5():
    # var result = _gettime_as_nsec_unix(6)
    # var result = time._gettime_as_nsec_unix(time._CLOCK_REALTIME) # ns 更精确
    var result = time._gettime_as_nsec_unix(_CLOCK_REALTIME_COARSE)  # ns 更快速
    keep(result)


fn bench_tscns_read_nanos():
    var result = tscns_read_nanos()
    keep(result)


fn main() raises:
    var ns = time._gettime_as_nsec_unix(time._CLOCK_REALTIME)
    print(ns)
    var ns_coarse = _gettime_as_nsec_unix(_CLOCK_REALTIME_COARSE)
    print(ns_coarse)
    tscns_init(INIT_CALIBRATE_NANOS, CALIBRATE_INTERVAL_NANOS)
    tscns_calibrate()
    var b = tscns_read_nanos()
    print(b)

    # var report = run[bench_perf_counter_ns]()
    var report0 = run[bench_perf_counter_ns5]()
    report0.print(Unit.ns)
    var report1 = run[bench_tscns_read_nanos]()
    report1.print(Unit.ns)
