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
    idgen_next_id,
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
    OnTickerC,
    OnTickersC,
    OnOrderBookC,
    OnTradeC,
    OnBalanceC,
    OnOrderC,
    OnMyTradeC,
    ticker_decorator,
    tickers_decorator,
    orderbook_decorator,
    trade_decorator,
    balance_decorator,
    order_decorator,
    mytrade_decorator,
    Any,
    Strings,
)
from ccxt.base.pro_exchangeable import ProExchangeable
from ccxt.foundation.binance import Binance as BinanceClient
# from ._common import *

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



alias WSCallback = fn (msg: String) raises -> None


struct Binance(ProExchangeable):
    var _app: String
    var _settle: String
    var _api_key: String
    var _api_secret: String
    var _testnet: Bool
    var _ws: UnsafePointer[WebSocket]
    var _on_ticker: OnTickerC
    var _on_tickers: OnTickersC
    var _on_order_book: OnOrderBookC
    var _on_trade: OnTradeC
    var _on_balance: OnBalanceC
    var _on_order: OnOrderC
    var _on_my_trade: OnMyTradeC
    var _uid: UnsafePointer[String]
    var _trading_context: TradingContext
    var _subscriptions: List[Dict[String, Any]]
    var _ticker_subscriptions: List[String]  # (symbol)
    var _order_book_subscriptions: List[Tuple[String, Int]]  # (symbol, levels)
    var _client: UnsafePointer[BinanceClient]
    var _is_private: Bool
    var _last_renewal_time: Int
    var _verbose: Bool

    fn __init__(
        out self,
        config: Dict[String, Any],
        trading_context: TradingContext,
    ):
        self._app = "futures"
        self._settle = config.get("settle", String("usdt")).string()
        self._api_key = config.get("api_key", String("")).string()
        self._api_secret = config.get("api_secret", String("")).string()
        self._testnet = config.get("testnet", False).bool()
        self._verbose = config.get("verbose", False).bool()
        self._is_private = config.get("is_private", False).bool()
        self._ws = UnsafePointer[WebSocket].alloc(1)
        self._on_ticker = ticker_decorator(empty_on_ticker)
        self._on_tickers = tickers_decorator(empty_on_tickers)
        self._on_order_book = orderbook_decorator(empty_on_order_book)
        self._on_trade = trade_decorator(empty_on_trade)
        self._on_balance = balance_decorator(empty_on_balance)
        self._on_order = order_decorator(empty_on_order)
        self._on_my_trade = mytrade_decorator(empty_on_my_trade)
        self._uid = UnsafePointer[String].alloc(1)
        self._trading_context = trading_context
        self._subscriptions = List[Dict[String, Any]]()
        self._ticker_subscriptions = List[String]()
        self._order_book_subscriptions = List[Tuple[String, Int]]()
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
        self._ticker_subscriptions = other._ticker_subscriptions
        self._order_book_subscriptions = other._order_book_subscriptions
        self._client = other._client
        other._client = UnsafePointer[BinanceClient]()
        self._is_private = other._is_private
        self._verbose = other._verbose
        self._last_renewal_time = other._last_renewal_time

    fn __del__(owned self):
        self._client.destroy_pointee()
        self._client.free()

    fn set_on_ticker(mut self, owned on_ticker: OnTickerC) -> None:
        self._on_ticker = on_ticker

    fn set_on_tickers(mut self, owned on_tickers: OnTickersC) -> None:
        self._on_tickers = on_tickers

    fn set_on_order_book(mut self, owned on_order_book: OnOrderBookC) -> None:
        self._on_order_book = on_order_book

    fn set_on_trade(mut self, owned on_trade: OnTradeC) -> None:
        self._on_trade = on_trade

    fn set_on_balance(mut self, owned on_balance: OnBalanceC) -> None:
        self._on_balance = on_balance

    fn set_on_order(mut self, owned on_order: OnOrderC) -> None:
        self._on_order = on_order

    fn set_on_my_trade(mut self, owned on_my_trade: OnMyTradeC) -> None:
        self._on_my_trade = on_my_trade

    fn connect(mut self, rt: MonoioRuntimePtr) raises -> None:
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

        # var topics = String()
        # topics = "xrpusdt@bookTicker"
        if self._is_private:
            var listen_key = self._client[].generate_listen_key()
            logi("listen_key=" + listen_key)
            path = "/ws/" + listen_key
        else:
            # https://developers.binance.com/docs/zh-CN/derivatives/usds-margined-futures/websocket-market-streams
            # 连接样例：
            # wss://fstream.binance.com/ws/bnbusdt@aggTrade
            # wss://fstream.binance.com/stream?streams=bnbusdt@aggTrade/btcusdt@markPrice
            # stream名称中所有交易对均为小写。
            # 每个链接有效期不超过24小时，请妥善处理断线重连。
            # path = "/stream?streams=" + topics
            path = "/ws/0"

        logd(
            "Connecting to Binance WebSocket at: wss://"
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
            try:
                self_ptr[].__on_open()
            except e:
                logw("__on_open error: " + str(e))

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

    fn __on_open(mut self) raises -> None:
        logd("__on_open")
        if self._is_private:
            self._last_renewal_time = now_ms()
        else:
            #
            for symbol in self._ticker_subscriptions:
                var symbol_ = symbol[].lower()
                var stream = String.format("{}@bookTicker", symbol_)
                self.subscribe(List[String](stream))

            #
            for sub in self._order_book_subscriptions:
                var symbol = sub[][0]
                var levels = sub[][1]
                var symbol_ = symbol.lower()
                var stream = String.format("{}@depth{}".format(symbol_, levels))
                self.subscribe(List[String](stream))

    @always_inline
    fn __on_message(mut self, message: String) -> None:
        """Handler for parsing WS messages."""
        logd("message: " + message)
        # {"stream":"xrpusdt@bookTicker","data":{"e":"bookTicker","u":6500077103850,"s":"XRPUSDT","b":"3.0290","B":"1850.6","a":"3.0291","A":"12824.3","T":1737442178641,"E":1737442178641}}

        # {"e":"ORDER_TRADE_UPDATE","T":1737448064726,"E":1737448064726,"o":{"s":"1000PEPEUSDT","c":"XgV42c0IEpacopoGASgVgo","S":"BUY","o":"LIMIT","f":"GTC","q":"1000","p":"0.0050000","ap":"0","sp":"0","x":"CANCELED","X":"CANCELED","i":16534440354,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1737448064726,"t":0,"b":"10","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"LONG","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}

        var json_obj = JsonObject(message)
        if self._is_private:
            var e = json_obj.get_str("e")
            if e == "ORDER_TRADE_UPDATE":
                self.__on_order(json_obj)
        else:
            var stream = json_obj.get_str("stream")
            if "bookTicker" in stream:
                self.__on_ticker(json_obj)

        _ = json_obj^

    @always_inline
    fn __on_ticker(self, json_obj: JsonObject) -> None:
        # {"stream":"xrpusdt@bookTicker","data":{"e":"bookTicker","u":6500077103850,"s":"XRPUSDT","b":"3.0290","B":"1850.6","a":"3.0291","A":"12824.3","T":1737442178641,"E":1737442178641}}
        # {
        #     "e":"bookTicker",		// 事件类型
        #     "u":400900217,     	// 更新ID
        #     "E": 1568014460893,	// 事件推送时间
        #     "T": 1568014460891,	// 撮合时间
        #     "s":"BNBUSDT",     	// 交易对
        #     "b":"25.35190000", 	// 买单最优挂单价格
        #     "B":"31.21000000", 	// 买单最优挂单数量
        #     "a":"25.36520000", 	// 卖单最优挂单价格
        #     "A":"40.66000000"  	// 卖单最优挂单数量
        # }
        var data = json_obj.get_object_mut("data")
        var symbol = data.get_str("s")
        var bid = Fixed(data.get_str("b"))
        var ask = Fixed(data.get_str("a"))
        var bid_size = data.get_str("B")
        var ask_size = data.get_str("A")
        var ticker = Ticker()
        ticker.symbol = symbol
        ticker.bid = bid
        ticker.ask = ask
        ticker.bidVolume = Fixed(bid_size)
        ticker.askVolume = Fixed(ask_size)
        ticker.timestamp = int(data.get_i64("E"))
        ticker.datetime = str(ticker.timestamp)
        self._on_ticker(self._trading_context, ticker)
        _ = data^

    @always_inline
    fn __on_order(self, json_obj: JsonObject) -> None:
        """
        {"e":"ORDER_TRADE_UPDATE","T":1737448064726,"E":1737448064726,"o":{"s":"1000PEPEUSDT","c":"XgV42c0IEpacopoGASgVgo","S":"BUY","o":"LIMIT","f":"GTC","q":"1000","p":"0.0050000","ap":"0","sp":"0","x":"CANCELED","X":"CANCELED","i":16534440354,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1737448064726,"t":0,"b":"10","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"LONG","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}

        {
            "e":"ORDER_TRADE_UPDATE",			// 事件类型
            "E":1568879465651,				    // 事件时间
            "T":1568879465650,				    // 撮合时间
            "o":{
                "s":"BTCUSDT",					    // 交易对
                "c":"TEST",						      // 客户端自定订单ID
                // 特殊的自定义订单ID:
                // "autoclose-"开头的字符串: 系统强平订单
                // "adl_autoclose": ADL自动减仓订单
                // "settlement_autoclose-": 下架或交割的结算订单
                "S":"SELL",						      // 订单方向
                "o":"TRAILING_STOP_MARKET",	// 订单类型
                "f":"GTC",						      // 有效方式
                "q":"0.001",					      // 订单原始数量
                "p":"0",						        // 订单原始价格
                "ap":"0",						        // 订单平均价格
                "sp":"7103.04",			        // 条件订单触发价格，对追踪止损单无效
                "x":"NEW",						      // 本次事件的具体执行类型
                "X":"NEW",						      // 订单的当前状态
                "i":8886774,					      // 订单ID
                "l":"0",						        // 订单末次成交量
                "z":"0",						        // 订单累计已成交量
                "L":"0",						        // 订单末次成交价格
                "N": "USDT",                // 手续费资产类型
                "n": "0",                   // 手续费数量
                "T":1568879465650,				  // 成交时间
                "t":0,							        // 成交ID
                "b":"0",						        // 买单净值
                "a":"9.91",						      // 卖单净值
                "m": false,					        // 该成交是作为挂单成交吗？
                "R":false	,				          // 是否是只减仓单
                "wt": "CONTRACT_PRICE",	    // 触发价类型
                "ot": "TRAILING_STOP_MARKET",	// 原始订单类型
                "ps":"LONG"						      // 持仓方向
                "cp":false,						      // 是否为触发平仓单; 仅在条件订单情况下会推送此字段
                "AP":"7476.89",					    // 追踪止损激活价格, 仅在追踪止损单时会推送此字段
                "cr":"5.0",						      // 追踪止损回调比例, 仅在追踪止损单时会推送此字段
                "pP": false,                // 是否开启条件单触发保护
                "si": 0,                    // 忽略
                "ss": 0,                    // 忽略
                "rp":"0",					          // 该交易实现盈亏
                "V":"EXPIRE_TAKER",         // 自成交防止模式
                "pm":"OPPONENT",            // 价格匹配模式
                "gtd":0                     // TIF为GTD的订单自动取消时间
            }
            }
        """
        var order = Order()
        var obj = json_obj.get_object_mut("o")
        order.id = str(obj.get_u64("i"))
        order.symbol = obj.get_str("s")
        order.status = obj.get_str("X")
        order.side = (
            OrderSide.Buy if obj.get_str("S") == "BUY" else OrderSide.Sell
        )
        order.price = Fixed(obj.get_str("p"))
        order.amount = Fixed(obj.get_str("q"))
        order.filled = Fixed(obj.get_str("z"))
        order.remaining = order.amount - order.filled
        order.timestamp = int(obj.get_i64("T"))
        order.datetime = str(order.timestamp)
        order.lastTradeTimestamp = order.timestamp
        order.lastUpdateTimestamp = order.timestamp
        order.clientOrderId = obj.get_str("c")
        order.timeInForce = String(obj.get_str("f"))

        order.fee = None  # TODO:
        order.trades = List[Trade]()
        order.reduceOnly = obj.get_bool("R")
        order.postOnly = obj.get_bool("m")
        order.stopPrice = Fixed(0)  # TODO:
        order.takeProfitPrice = Fixed(0)  # TODO:
        order.stopLossPrice = Fixed(0)  # TODO:
        order.cost = Fixed(0)  # TODO:
        order.info = Dict[String, Any]()  # TODO:

        _ = obj^

        self._on_order(self._trading_context, order)

    fn __on_ping(self) -> None:
        logd("__on_ping")

    fn __on_error(self, error: String) -> None:
        logd("__on_error: " + error)

    fn __on_close(self) -> None:
        logd("__on_close")

    fn __on_timer(mut self, count: UInt64) -> None:
        logd("__on_timer")
        if self._is_private:
            self.__extend_listen_key()

    fn __extend_listen_key(mut self):
        var now = now_ms()
        if now - self._last_renewal_time <= 1000 * 60 * 5:
            return

        try:
            var ret = self._client[].extend_listen_key_with_callback()
            logd("extend_listen_key ret: " + str(ret))
        except e:
            loge("extend_listen_key error: " + str(e))
        self._last_renewal_time = now

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
        # <symbol>@bookTicker
        self._ticker_subscriptions.append(symbol)

    fn subscribe_tickers(
        mut self, symbols: Strings, params: Dict[String, Any]
    ) raises -> None:
        for symbol in symbols.value():
            self.subscribe_ticker(symbol[], params)

    fn subscribe_order_book(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        """推送有限档深度信息。levels表示几档买卖单信息, 可选 5/10/20档."""
        # <symbol>@depth<levels>
        var levels = params["levels"].int() if "levels" in params else 5
        var sub = Tuple[String, Int](symbol, levels)
        self._order_book_subscriptions.append(sub)

    fn subscribe_trade(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe_balance(mut self, params: Dict[String, Any]) raises -> None:
        pass

    fn subscribe_order(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe_my_trades(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe(self, streams: List[String]) raises:
        var id = idgen_next_id()
        var request = JsonObject()
        request.insert_str("method", "SUBSCRIBE")
        var stream_array = JsonArray()
        for stream in streams:
            stream_array.push_str(stream[])
        request.insert_array("params", stream_array)
        request.insert_i64("id", id)
        var request_text = str(request)
        if self._verbose:
            logd("subscribe: " + request_text)
        self.send(request_text)

    fn unsubscribe(self, streams: List[String]) raises:
        var id = idgen_next_id()
        var request = JsonObject()
        request.insert_str("method", "UNSUBSCRIBE")
        var stream_array = JsonArray()
        for stream in streams:
            stream_array.push_str(stream[])
        request.insert_array("params", stream_array)
        request.insert_i64("id", id)
        var request_text = str(request)
        if self._verbose:
            logd("subscribe: " + request_text)
        self.send(request_text)
