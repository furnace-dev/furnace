import hashlib
import time
from memory import UnsafePointer, stack_allocation
from collections import Dict
from monoio_connect import (
    now_ms,
    WebSocket,
    WebSocketOpenCallback,
    WebSocketMessageCallback,
    WebSocketPingCallback,
    WebSocketErrorCallback,
    WebSocketCloseCallback,
    WebSocketTimerCallback,
    logd,
    logi,
    loge,
    logw,
    Fixed,
    compute_sha512_hex,
    compute_hmac_sha512_hex,
    HttpClientOptions,
    HttpClient,
    Headers,
    Method,
    HttpResponsePtr,
    MonoioRuntimePtr,
    http_response_status_code,
    http_response_body,
)
from sonic import *
from ccxt.base.types import (
    TradingContext,
    Ticker,
    OrderBook,
    Trade,
    Balance,
    Order,
    OrderSide,
    OnTicker,
    OnTickers,
    OnOrderBook,
    OnTrade,
    OnBalance,
    OnOrder,
    OnMyTrade,
    Any,
    Strings,
)
from ccxt.base.pro_exchangeable import ProExchangeable
from ccxt.foundation.binance import Binance as BinanceClient


alias WSCallback = fn (msg: String) raises -> None


fn empty_on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    pass


fn empty_on_tickers(
    trading_context: TradingContext, tickers: List[Ticker]
) -> None:
    pass


fn empty_on_order_book(
    trading_context: TradingContext, order_book: OrderBook
) -> None:
    pass


fn empty_on_trade(trading_context: TradingContext, trade: Trade) -> None:
    pass


fn empty_on_balance(trading_context: TradingContext, balance: Balance) -> None:
    pass


fn empty_on_order(trading_context: TradingContext, order: Order) -> None:
    pass


fn empty_on_my_trade(trading_context: TradingContext, trade: Trade) -> None:
    pass


struct Binance(ProExchangeable):
    var _app: String
    var _settle: String
    var _api_key: String
    var _api_secret: String
    var _testnet: Bool
    var _ws: UnsafePointer[WebSocket]
    var _on_ticker: OnTicker
    var _on_tickers: OnTickers
    var _on_order_book: OnOrderBook
    var _on_trade: OnTrade
    var _on_balance: OnBalance
    var _on_order: OnOrder
    var _on_my_trade: OnMyTrade
    var _uid: UnsafePointer[String]
    var _trading_context: TradingContext
    var _subscriptions: List[Dict[String, Any]]
    var _client: UnsafePointer[BinanceClient]
    var _is_private: Bool
    var _last_renewal_time: Int
    var _verbose: Bool

    fn __init__(
        out self,
        config: Dict[String, Any],
        trading_context: TradingContext,
    ) raises:
        self._app = "futures"
        self._settle = str(config["settle"]) if "settle" in config else "usdt"
        self._api_key = str(config["api_key"]) if "api_key" in config else ""
        self._api_secret = (
            str(config["api_secret"]) if "api_secret" in config else ""
        )
        self._testnet = (
            config["testnet"].bool() if "testnet" in config else False
        )
        self._is_private = (
            config["is_private"].bool() if "is_private" in config else False
        )
        self._verbose = (
            config["verbose"].bool() if "verbose" in config else False
        )
        self._ws = UnsafePointer[WebSocket].alloc(1)
        self._on_ticker = empty_on_ticker
        self._on_tickers = empty_on_tickers
        self._on_order_book = empty_on_order_book
        self._on_trade = empty_on_trade
        self._on_balance = empty_on_balance
        self._on_order = empty_on_order
        self._on_my_trade = empty_on_my_trade
        self._uid = UnsafePointer[String].alloc(1)
        self._trading_context = trading_context
        self._subscriptions = List[Dict[String, Any]]()
        self._client = UnsafePointer[BinanceClient].alloc(1)
        self._last_renewal_time = 0

    fn __moveinit__(out self: Self, owned other: Self):
        self._app = other._app
        self._settle = other._settle
        self._api_key = other._api_key
        self._api_secret = other._api_secret
        self._testnet = other._testnet
        self._ws = other._ws
        self._on_ticker = other._on_ticker
        self._on_tickers = other._on_tickers
        self._on_order_book = other._on_order_book
        self._on_trade = other._on_trade
        self._on_balance = other._on_balance
        self._on_order = other._on_order
        self._on_my_trade = other._on_my_trade
        self._uid = other._uid
        self._trading_context = other._trading_context
        self._subscriptions = other._subscriptions
        self._client = other._client
        other._client = UnsafePointer[BinanceClient]()
        self._is_private = other._is_private
        self._verbose = other._verbose
        self._last_renewal_time = other._last_renewal_time

    fn __del__(owned self: Self):
        pass

    fn set_on_ticker(mut self: Self, on_ticker: OnTicker) raises -> None:
        self._on_ticker = on_ticker

    fn set_on_tickers(mut self: Self, on_tickers: OnTickers) raises -> None:
        self._on_tickers = on_tickers

    fn set_on_order_book(
        mut self: Self, on_order_book: OnOrderBook
    ) raises -> None:
        self._on_order_book = on_order_book

    fn set_on_trade(mut self: Self, on_trade: OnTrade) raises -> None:
        self._on_trade = on_trade

    fn set_on_balance(mut self: Self, on_balance: OnBalance) raises -> None:
        self._on_balance = on_balance

    fn set_on_order(mut self: Self, on_order: OnOrder) raises -> None:
        self._on_order = on_order

    fn set_on_my_trade(mut self: Self, on_my_trade: OnMyTrade) raises -> None:
        self._on_my_trade = on_my_trade

    fn connect(mut self: Self, rt: MonoioRuntimePtr) raises -> None:
        """
        Connect to the Binance API.
        """
        var config: Dict[String, Any] = Dict[String, Any]()
        config["api_key"] = self._api_key
        config["api_secret"] = self._api_secret
        config["testnet"] = self._testnet
        if self._verbose:
            config["verbose"] = True
        __get_address_as_uninit_lvalue(self._client.address) = BinanceClient(
            config, self._trading_context, rt
        )

        var host: String = "stream.binancefuture.com" if self._testnet else "fstream.binance.com"
        var port = 443
        var path = String()

        var topics = String()
        topics = "XRPUSDT@bookTicker"
        if self._is_private:
            var listen_key = self._client[].generate_listen_key()
            logi("listen_key=" + listen_key)
            path = "/ws/" + listen_key
        else:
            path = "/stream?streams=" + topics

        logd(
            "Connecting to Binance WebSocket at: "
            + host
            + ":"
            + str(port)
            + path
        )

        __get_address_as_uninit_lvalue(self._ws.address) = WebSocket(
            host=host, port=port, path=path
        )

        var on_open = self.get_on_open()
        var on_message = self.get_on_message()
        var on_ping = self.get_on_ping()
        var on_error = self.get_on_error()
        var on_close = self.get_on_close()
        var on_timer = self.get_on_timer()

        self._ws[].set_on_open(on_open^)
        self._ws[].set_on_message(on_message^)
        self._ws[].set_on_ping(on_ping^)
        self._ws[].set_on_error(on_error^)
        self._ws[].set_on_close(on_close^)
        self._ws[].set_on_timer(on_timer^)

        self._ws[0].run(rt)

    fn get_on_open(mut self) -> WebSocketOpenCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].__on_open()

        return wrapper

    fn get_on_message(mut self) -> WebSocketMessageCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(msg: String):
            self_ptr[].__on_message(msg)

        return wrapper

    fn get_on_ping(mut self) -> WebSocketPingCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].__on_ping()

        return wrapper

    fn get_on_error(mut self) -> WebSocketErrorCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(err: String):
            self_ptr[].__on_error(err)

        return wrapper

    fn get_on_close(mut self) -> WebSocketCloseCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].__on_close()

        return wrapper

    fn get_on_timer(mut self) -> WebSocketTimerCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(count: UInt64):
            self_ptr[].__on_timer(count)

        return wrapper

    fn __on_open(mut self) -> None:
        logd("__on_open")
        self._last_renewal_time = now_ms()

    @always_inline
    fn __on_message(mut self, message: String) -> None:
        """Handler for parsing WS messages."""
        # TODO: refactor
        logd("message: " + message)
        # {"error":{"code":2,"msg":"Invalid request: missing field `method`"},"id":null}

        var json_obj = JsonObject(message)

        # var channel = json_obj.get_str_ref("channel")
        # # logd("channel: " + str(channel))
        # if channel == "futures.book_ticker":
        #     self.__on_ticker(json_obj)
        # elif channel == "futures.order_book_update":
        #     self.__on_order_book_update(json_obj)
        # elif channel == "futures.orders":
        #     self.__on_orders(json_obj)
        # elif channel == "futures.pong":
        #     self.__on_pong(json_obj)
        # else:
        #     logi("unknown channel: " + str(channel))

        _ = json_obj^

    fn __on_ping(self) -> None:
        logd("__on_ping")

    fn __on_error(self, error: String) -> None:
        logd("__on_error: " + error)

    fn __on_close(self) -> None:
        logd("__on_close")

    fn __on_timer(mut self, count: UInt64) -> None:
        logd("__on_timer")
        var now = now_ms()
        if now - self._last_renewal_time > 1000 * 60 * 5:
            try:
                var ret = self._client[].extend_listen_key_with_callback()
                logd("extend_listen_key ret: " + str(ret))
            except e:
                loge("extend_listen_key error: " + str(e))
            self._last_renewal_time = now

    @always_inline
    fn __on_ticker(self, json_obj: JsonObject) -> None:
        # TODO: refactor
        var event = json_obj.get_str_ref("event")
        if event == "update":
            # var result = json_obj.get_object_mut("result")
            # var symbol = String(result.get_str_ref("s"))
            # var bid = Fixed(result.get_str_ref("b"))
            # var ask = Fixed(result.get_str_ref("a"))
            # var bid_size = result.get_i64("B")
            # var ask_size = result.get_i64("A")
            # var ticker = Ticker()
            # ticker.symbol = symbol
            # ticker.bid = bid
            # ticker.ask = ask
            # ticker.bidVolume = Fixed(bid_size)
            # ticker.askVolume = Fixed(ask_size)
            # ticker.timestamp = int(result.get_i64("t"))
            # ticker.datetime = str(result.get_i64("time"))
            # self._on_ticker(self._trading_context, ticker)
            # _ = result^
            pass
        elif event == "subscribe":
            pass
        else:
            logi("unknown event: " + str(event))

    @always_inline
    fn __on_orders(self, json_obj: JsonObject) -> None:
        # TODO: refactor
        var event = json_obj.get_str_ref("event")
        if event == "update":
            # 订单更新
            var result = json_obj.get_array_mut("result")
            # assert_true(result.len() > 0)
            if result.len() == 0:
                return

            var list_iter = result.iter_mut()
            var orders = List[Order](capacity=result.len())
            while True:
                var value = list_iter.next()
                if value.is_null():
                    break

                var order = Order()
                var obj = value.as_object_mut()
                order.id = str(obj.get_u64("id"))
                order.symbol = obj.get_str_ref("contract")
                order.status = obj.get_str_ref("status")
                order.side = OrderSide.Buy  # TODO:
                order.price = Fixed(obj.get_f64("price"))
                order.amount = Fixed(obj.get_i64("size"))
                order.remaining = Fixed(obj.get_i64("left"))
                order.filled = order.amount - order.remaining
                order.datetime = str(obj.get_i64("create_time"))  # TODO:
                order.timestamp = int(obj.get_i64("create_time_ms"))
                order.lastTradeTimestamp = int(obj.get_i64("create_time_ms"))
                order.lastUpdateTimestamp = order.lastTradeTimestamp
                order.clientOrderId = obj.get_str_ref("text")
                order.timeInForce = String(obj.get_str_ref("tif"))
                order.fee = None  # TODO:
                order.trades = List[Trade]()  # TODO:
                order.reduceOnly = False  # TODO:
                order.postOnly = False  # TODO:
                order.stopPrice = Fixed(0)  # TODO:
                order.takeProfitPrice = Fixed(0)  # TODO:
                order.stopLossPrice = Fixed(0)  # TODO:
                order.cost = Fixed(0)  # TODO:
                order.info = Dict[String, Any]()  # TODO:
                orders.append(order)
                _ = obj^

            _ = list_iter^
            _ = result^

            for order in orders:
                self._on_order(self._trading_context, order[])

        elif event == "subscribe":
            pass
        else:
            logi("unknown event: " + str(event))

    @always_inline
    fn __on_pong(self, json_obj: JsonObject) -> None:
        logd("__on_pong")

    fn _on_login(mut self) -> None:
        logd("_on_login")

    fn send(self, data: String) -> None:
        _ = self._ws[0].send(data)

    fn subscribe_ticker(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # TODO: refactor
        var sub = Dict[String, Any]()
        sub["type"] = "ticker"
        sub["symbol"] = symbol
        self._subscriptions.append(sub)

    fn subscribe_tickers(
        mut self, symbols: Strings, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe_order_book(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # TODO: refactor
        var sub = Dict[String, Any]()
        sub["type"] = "order_book"
        sub["symbol"] = symbol
        sub["interval"] = "100ms"
        self._subscriptions.append(sub)

    fn subscribe_trade(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # TODO: refactor
        var sub = Dict[String, Any]()
        sub["type"] = "trade"
        sub["symbol"] = symbol
        self._subscriptions.append(sub)

    fn subscribe_balance(mut self, params: Dict[String, Any]) raises -> None:
        pass

    fn subscribe_order(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # TODO: refactor
        var sub = Dict[String, Any]()
        sub["type"] = "order"
        sub["symbol"] = symbol
        self._subscriptions.append(sub)

    fn subscribe_my_trades(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe(
        self, name: String, owned payload: JsonValue, require_auth: Bool
    ) raises:
        # TODO: refactor
        # var request = WebSocketRequest(
        #     self._api_key,
        #     self._api_secret,
        #     name,
        #     "subscribe",
        #     payload^,
        #     require_auth,
        # )
        # var request_text = str(request)
        # # {"time":1733898511,"channel":"futures.order_book","event":"subscribe","payload":["BTC_USDT","100ms"]}
        # logd("subscribe: " + request_text)
        # self.send(request_text)
        pass

    fn unsubscribe(
        self, name: String, owned payload: JsonValue, require_auth: Bool
    ) raises:
        # TODO: refactor
        # var request = WebSocketRequest(
        #     self._api_key,
        #     self._api_secret,
        #     name,
        #     "unsubscribe",
        #     payload^,
        #     require_auth,
        # )
        # self.send(str(request))
        pass

    fn login(self, header: String, req_id: String) raises:
        """
        Login to the Binance API.
        """
        # TODO: refactor
        # var channel = String.format("{}.login", self._app)
        # var text = ApiRequest(
        #     self._api_key,
        #     self._api_secret,
        #     channel,
        #     header,
        #     req_id,
        #     JsonValue.from_str("{}"),
        # ).gen()
        # logd("login: " + text)
        # # {"time":1733900436,"channel":"futures.login","event":"api","payload":{"req_header":{"X-Gate-Channel-Id":"header"},"api_key":"10d23703c09150b1bf4c5bb7f0f1dd2e","timestamp":"1733900436","signature":"317580edef0b1bd60b50bd7c618fa5f68dc3c0874e27cc1f9b3f84a747b478b90e99c31f0c1fb9720639ba3281ec1dfa469e1bbff3ecd62f4c8ec047f964e590","req_id":"Be4Ts0I4OZ6r9msg_pFu-","req_param":{}}}
        # self.send(text)
        pass
