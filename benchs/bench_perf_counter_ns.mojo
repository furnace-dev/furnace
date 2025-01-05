from benchmark import Unit, keep, run
from time import sleep, perf_counter_ns


fn bench_perf_counter_ns():
    var result = perf_counter_ns()
    keep(result)


fn main() raises:
    var report = run[bench_perf_counter_ns]()
    report.print(Unit.ns)
