import time
from memory import UnsafePointer, memcpy
from sys.ffi import DLHandle, c_char, c_size_t

from utils import StringRef
from testing import assert_equal, assert_true
from monoio_connect import *
from monoio_connect.internal import *
from monoio_connect.pthread import *
from monoio_connect.internal.monoio import MonoioRuntimePtr, StrBoxed, free_str
from monoio_connect.timeutil import now_ms


alias c_char_ptr = UnsafePointer[c_char]


fn task_entry(data: TaskEntryArg) -> Int32:
    print("task_entry")
    return 0


fn thread_run(arg: UnsafePointer[UInt8]) -> UInt8:
    print("thread_run")
    var rt = create_monoio_runtime()
    block_on_runtime(rt, task_entry, arg)

    return 0


fn monoio_test() raises:
    var rt = create_monoio_runtime()
    var arg = TaskEntryArg()
    # block_on_runtime(rt, task_entry, arg)
    # start_task(task_entry, arg)
    spawn_task_on_runtime(rt, task_entry, arg)

    print("done")

    block_on_runtime(rt, task_entry, TaskEntryArg())
    # destroy_client_builder(rt)

    # 启动线程
    var tid: UInt64 = 0
    _ = pthread_create(tid, thread_run)
    print("tid: " + str(tid))

    time.sleep(10.0)

    _ = rt


fn channel_test() raises:
    var channel = create_channel(0, 1024)

    var data = UnsafePointer[TestData].alloc(1)
    data.init_pointee_move(TestData(id=100, name="hello"))
    var ret = channel_send(channel, data.bitcast[UInt8]())
    assert_equal(ret, 0)

    var data2 = channel_recv(channel)
    var data2_ptr = data2.bitcast[TestData]()
    assert_equal(data2_ptr[].id, 100)
    assert_equal(data2_ptr[].name, "hello")

    # data2.free()
    data2_ptr.free()

    time.sleep(10.0)

    destroy_channel(channel)


@value
struct TestData(Stringable):
    var id: UInt64
    var name: String
    var ts0: Int64
    var ts1: Int64

    fn __init__(out self, id: UInt64, name: String):
        self.id = id
        self.name = name
        # self.ts0 = time.perf_counter_ns()
        self.ts0 = tscns_read_nanos()
        self.ts1 = 0

    fn __str__(self) -> String:
        return (
            "TestData(id="
            + str(self.id)
            + ", name="
            + self.name
            + ", ts0="
            + str(self.ts0)
            + ", ts1="
            + str(self.ts1)
            + ", diff="
            + str(self.ts1 - self.ts0)
            + " ns)"
        )


fn recv_task_monoio(arg: TaskEntryArg) -> Int32:
    print("recv_task_monoio")
    bind_to_cpu_set(0)
    var channel: ChannelPtr = arg
    print(str(channel))
    while True:
        var data = channel_recv(channel)
        if data == UnsafePointer[c_void]():
            continue
        var data_ptr = data.bitcast[TestData]()
        # data_ptr[].ts1 = time.perf_counter_ns()
        data_ptr[].ts1 = tscns_read_nanos()
        print(str(data_ptr[]))
        data.free()
    # return 0


fn recv_task(arg: UnsafePointer[UInt8]) -> UInt8:
    print("recv_task")
    var rt = create_monoio_runtime()
    block_on_runtime(rt, recv_task_monoio, arg)
    # destroy_monoio_runtime(rt)
    return 0


fn channel_test2() raises:
    var channel = create_channel(2, 1024)
    var tid: UInt64 = 0
    _ = pthread_create(tid, recv_task, channel)
    print("tid: " + str(tid))

    while True:
        var data = UnsafePointer[TestData].alloc(1)
        # data.init_pointee_move(TestData(id=100, name="hello"))
        __get_address_as_uninit_lvalue(data.address) = TestData(
            id=100, name="hello"
        )
        var ret = channel_send(channel, data.bitcast[UInt8]())
        assert_equal(ret, 0)
        # time.sleep(0.01)
        time.sleep(0.2)

    # time.sleep(10.0)

    # destroy_channel(channel)


fn header_map_test() raises:
    var hm = HeaderMap()
    hm.set("a", "b")
    # print(hm.get("a"))
    assert_equal(hm.get("a"), "b")
    assert_equal(hm.get("b"), "")
    assert_equal(hm.get[2048]("b"), "")


fn http_raw_test() raises:
    var url = String("https://www.baidu.com")
    var payload = String("")
    var req = new_http_request(
        Method.METHOD_GET,
        url.unsafe_cstr_ptr(),
        HttpVersion.HTTP_VERSION_HTTP11,
        payload.unsafe_cstr_ptr(),
    )
    print(str(req))
    # var rt = create_monoio_runtime()
    # var resp = http_client_request(rt, c, req)
    # print(str(resp))
    # destroy_http_request(req)
    # destroy_http_response(resp)
    # destroy_monoio_runtime(rt)


fn http_test() raises:
    var base_url = String("https://www.baidu.com")
    var options = HttpClientOptions(base_url=base_url)
    var http = HttpClient(options)
    var headers = Headers()
    headers["a"] = "b"
    var resp = http.request("/", Method.METHOD_GET, headers, "")
    print(resp.status_code)
    print(resp.text)


fn http_callback(
    req_id: UInt64,
    type_: UInt32,
    source: UnsafePointer[c_void],
    res: HttpResponsePtr,
) -> None:
    print("http_callback req_id: " + str(req_id))
    print("http_callback status_code: " + str(http_response_status_code(res)))
    alias buf_size = 1024 * 1000
    var buf = stack_allocation[buf_size, Int8]()
    var body = http_response_body(res, buf, buf_size)
    print("http_callback text: " + str(String(StringRef(buf, body))))
    # destroy_http_response(res)


fn http_callback_test() raises:
    var rt = create_monoio_runtime()
    var base_url = String("https://www.baidu.com")
    var options = HttpClientOptions(base_url=base_url)
    var http = HttpClient(options, rt)
    var headers = Headers()
    headers["a"] = "b"
    http.request_with_callback(
        "/", Method.METHOD_GET, headers, "", 0, http_callback
    )
    print("done")
    monoio_sleep_ms(rt, 10000)
    _ = http^
    # destroy_monoio_runtime(rt)


fn idgen_test() raises:
    # idgen_set_options(0, 6, 6)
    # idgen_set_worker_id(0)
    var id = idgen_next_id()
    print("id: " + str(id))


fn ws_on_open(id: Int64, ws: UnsafePointer[c_void]) -> None:
    print("ws_on_open ws: " + str(ws) + " ws_id: " + str(int(ws)))

    # 发送一个消息
    # var text = String("hello")
    # var ret = ws_send_text(MonoioRuntimePtr(), ws, text.unsafe_cstr_ptr())
    # print("ws_send_text ret: " + str(ret))
    # assert_equal(ret, 0)

    var ts = int(now_ms() / 1000)
    #
    var text = String(
        '{"time": 123456, "channel": "futures.book_ticker", "event":'
        ' "subscribe", "payload": ["XRP_USDT"]}'
    )
    # var text = String('{"time": 123456, "channel": "futures.order_book", "event": "subscribe", "payload": ["BTC_USDT", "20", "0"]}')
    text = text.replace("123456", str(ts))
    print("text: " + str(text))
    var ret = ws_send_text(ws, text.unsafe_cstr_ptr())
    print("ws_send_text ret: " + str(ret))


fn ws_on_message(id: Int64, ws: UnsafePointer[c_void], msg: StrBoxed) -> None:
    # print("ws_on_message ws: " + str(ws))
    var s = String(StringRef(msg.ptr, msg.len))
    # print("s: " + str(s))
    free_str(msg)


fn ws_on_ping(id: Int64, ws: UnsafePointer[c_void]) -> None:
    print("ws_on_ping ws: " + str(ws))


fn ws_on_error(id: Int64, ws: UnsafePointer[c_void], err: StrBoxed) -> None:
    print("ws_on_error ws: " + str(ws))


fn ws_on_close(id: Int64, ws: UnsafePointer[c_void]) -> None:
    print("ws_on_close ws: " + str(ws))


fn ws_on_timer(id: Int64, ws: UnsafePointer[c_void], count: UInt64) -> None:
    print("ws_on_timer ws: " + str(ws) + " count: " + str(count))
    # ws.send('{"time" : 123456, "channel" : "futures.ping"}')
    # 发送一个ping消息
    var text = String('{"time": 123456, "channel": "futures.ping"}')
    var ts = int(now_ms() / 1000)
    text = text.replace("123456", str(ts))
    var ret = ws_send_text(ws, text.unsafe_cstr_ptr())
    print("ws_send_text ret: " + str(ret))


fn ws_test() raises:
    var rt = create_monoio_runtime()
    var uri = String("echo.websocket.org")
    var port = 443
    var path = String("/")

    var ret = connect_ws(
        rt,
        0,
        uri.unsafe_cstr_ptr(),
        port,
        path.unsafe_cstr_ptr(),
        10,
        ws_on_open,
        ws_on_message,
        ws_on_ping,
        ws_on_error,
        ws_on_close,
        ws_on_timer,
    )
    assert_equal(ret, 0)

    _ = rt


fn gate_ws_test() raises:
    var rt = create_monoio_runtime()
    var id = 1
    var uri = String("fx-ws.gateio.ws")
    var port = 443
    var path = String("/v4/ws/usdt")

    var ret = connect_ws(
        rt,
        id,
        uri.unsafe_cstr_ptr(),
        port,
        path.unsafe_cstr_ptr(),
        10,
        ws_on_open,
        ws_on_message,
        ws_on_ping,
        ws_on_error,
        ws_on_close,
        ws_on_timer,
    )
    assert_equal(ret, 0)

    _ = rt


struct WebSocketWrapper:
    var _ws: UnsafePointer[WebSocket]

    fn __init__(out self, host: String, port: Int, path: String):
        print("WebSocketWrapper.__init__")
        self._ws = UnsafePointer[WebSocket].alloc(1)
        __get_address_as_uninit_lvalue(self._ws.address) = WebSocket(
            host=host, port=port, path=path
        )
        print("WebSocketWrapper.__init__ done")

    fn get_on_open(mut self) -> WebSocketOpenCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].on_open()

        return wrapper

    fn get_on_message(mut self) -> WebSocketMessageCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(msg: String):
            self_ptr[].on_message(msg)

        return wrapper

    fn get_on_ping(mut self) -> WebSocketPingCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].on_ping()

        return wrapper

    fn get_on_error(mut self) -> WebSocketErrorCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(err: String):
            self_ptr[].on_error(err)

        return wrapper

    fn get_on_close(mut self) -> WebSocketCloseCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].on_close()

        return wrapper

    fn get_on_timer(mut self) -> WebSocketTimerCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(count: UInt64):
            self_ptr[].on_timer(count)

        return wrapper

    fn on_open(mut self: Self) -> None:
        print("on_open")
        # 订阅
        var ts = int(now_ms() / 1000)
        var text = String(
            '{"time": 123456, "channel": "futures.book_ticker", "event":'
            ' "subscribe", "payload": ["XRP_USDT"]}'
        )
        text = text.replace("123456", str(ts))
        print("text: " + str(text))
        var ret = self._ws[].send(text)
        print("ws_send_text ret: " + str(ret))

    fn on_message(mut self: Self, msg: String) -> None:
        print("on_message: " + msg)

    fn on_ping(mut self: Self) -> None:
        print("on_ping")

    fn on_error(mut self: Self, err: String) -> None:
        print("on_error: " + err)

    fn on_close(mut self: Self) -> None:
        print("on_close")

    fn on_timer(mut self: Self, count: UInt64) -> None:
        print("on_timer: " + str(count))
        var text = String('{"time": 123456, "channel": "futures.ping"}')
        var ts = int(now_ms() / 1000)
        text = text.replace("123456", str(ts))
        var ret = self._ws[].send(text)
        print("ws_send_text ret: " + str(ret))

    fn run(mut self: Self) -> None:
        print("start")
        var on_open = self.get_on_open()
        print("get_on_open")
        var on_message = self.get_on_message()
        print("get_on_message")
        var on_ping = self.get_on_ping()
        print("get_on_ping")
        var on_error = self.get_on_error()
        print("get_on_error")
        var on_close = self.get_on_close()
        print("get_on_close")
        var on_timer = self.get_on_timer()
        print("get_on_timer")

        self._ws[].set_on_open(on_open^)
        print("set_on_open")
        self._ws[].set_on_message(on_message^)
        print("set_on_message")
        self._ws[].set_on_ping(on_ping^)
        print("set_on_ping")
        self._ws[].set_on_error(on_error^)
        print("set_on_error")
        self._ws[].set_on_close(on_close^)
        print("set_on_close")
        self._ws[].set_on_timer(on_timer^)
        print("set_on_timer")

        print("run")
        self._ws[].run()
        print("done")


fn websocket_test() raises:
    print("websocket_test")
    var host = String("fx-ws.gateio.ws")
    var port = 443
    var path = String("/v4/ws/usdt")
    print("WebSocketWrapper")
    var ws = WebSocketWrapper(host, port, path)
    print("WebSocketWrapper done")
    ws.run()


fn log_test() raises:
    var logger = init_logger(LogLevel.Debug, "", "")
    test_log()
    logi("hello")
    destroy_logger(logger)


fn tscns_test() raises:
    # tscns_init(INIT_CALIBRATE_NANOS, CALIBRATE_INTERVAL_NANOS)
    # tscns_calibrate()
    var ns = tscns_read_nanos()
    print("tscns_read_nanos: " + str(ns))
    assert_true(ns > 1735996711599105344)


fn main() raises:
    tscns_init(INIT_CALIBRATE_NANOS, CALIBRATE_INTERVAL_NANOS)
    tscns_calibrate()
    # base_test()
    # monoio_test()
    # channel_test()
    # channel_test2()
    # header_map_test()
    # http_test()
    # http_test2()
    # idgen_test()
    # ws_test()
    # gate_ws_test()
    # websocket_test()
    # test_http_client()
    # http_raw_test()
    # http_test()
    # http_callback_test()
    log_test()
    # tscns_test()
    # time.sleep(1000.0)
