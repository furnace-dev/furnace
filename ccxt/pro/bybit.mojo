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
    compute_hmac_sha256_hex,
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
from sonic import (
    JsonObject,
    JsonArray,
    JsonValueRefObjectView,
)
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
    Any,
    Strings,
    ticker_decorator,
    tickers_decorator,
    orderbook_decorator,
    trade_decorator,
    balance_decorator,
    order_decorator,
    mytrade_decorator,
)
from ccxt.base.pro_exchangeable import ProExchangeable
from ccxt.foundation._base import (
    empty_on_ticker,
    empty_on_tickers,
    empty_on_order_book,
    empty_on_trade,
    empty_on_balance,
    empty_on_order,
    empty_on_my_trade,
)


struct Bybit(ProExchangeable):
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
    var _trading_context: TradingContext
    var _is_private: Bool
    var _verbose: Bool
    var _category: String
    var _subscription_topics: List[String]

    fn __init__(
        out self, config: Dict[String, Any], trading_context: TradingContext
    ):
        self._api_key = config.get("api_key", String("")).string()
        self._api_secret = config.get("api_secret", String("")).string()
        self._testnet = config.get("testnet", False).bool()
        self._is_private = config.get("is_private", False).bool()
        self._verbose = config.get("verbose", False).bool()
        self._ws = UnsafePointer[WebSocket].alloc(1)
        self._on_ticker = ticker_decorator(empty_on_ticker)
        self._on_tickers = tickers_decorator(empty_on_tickers)
        self._on_order_book = orderbook_decorator(empty_on_order_book)
        self._on_trade = trade_decorator(empty_on_trade)
        self._on_balance = balance_decorator(empty_on_balance)
        self._on_order = order_decorator(empty_on_order)
        self._on_my_trade = mytrade_decorator(empty_on_my_trade)
        self._trading_context = trading_context
        self._category = "linear"
        self._subscription_topics = List[String]()

    fn __moveinit__(out self: Self, owned other: Self):
        self._api_key = other._api_key
        self._api_secret = other._api_secret
        self._testnet = other._testnet
        self._is_private = other._is_private
        self._verbose = other._verbose
        self._ws = other._ws
        self._on_ticker = other._on_ticker
        self._on_tickers = other._on_tickers
        self._on_order_book = other._on_order_book
        self._on_trade = other._on_trade
        self._on_balance = other._on_balance
        self._on_order = other._on_order
        self._on_my_trade = other._on_my_trade
        self._trading_context = other._trading_context
        self._category = other._category
        self._subscription_topics = other._subscription_topics

    fn set_on_ticker(mut self, on_ticker: OnTickerC) -> None:
        self._on_ticker = on_ticker

    fn set_on_tickers(mut self, on_tickers: OnTickersC) -> None:
        self._on_tickers = on_tickers

    fn set_on_order_book(mut self, on_order_book: OnOrderBookC) -> None:
        self._on_order_book = on_order_book

    fn set_on_trade(mut self, on_trade: OnTradeC) -> None:
        self._on_trade = on_trade

    fn set_on_balance(mut self, on_balance: OnBalanceC) -> None:
        self._on_balance = on_balance

    fn set_on_order(mut self, on_order: OnOrderC) -> None:
        self._on_order = on_order

    fn set_on_my_trade(mut self, on_my_trade: OnMyTradeC) -> None:
        self._on_my_trade = on_my_trade

    fn connect(mut self, rt: MonoioRuntimePtr) raises -> None:
        """
        Connect to the Bybit API.
        """
        var host: String = "stream-testnet.bybit.com" if self._testnet else "stream.bybit.com"
        var port = 443
        var path = String()

        if self._is_private:
            path = "/v5/private"
        else:
            path = "/v5/public/" + self._category

        logd(
            "Connecting to Bybit WebSocket at: wss://"
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
            var param = self.generate_auth_payload()
            logd("auth: " + param)
            _ = self._ws[].send(param)
        else:
            self._subscribe()

    @always_inline
    fn __on_message(mut self, message: String) -> None:
        """Handler for parsing WS messages."""
        if self._verbose:
            logd("message: " + message)

        # 心跳消息
        # {"success":true,"ret_msg":"pong","conn_id":"9707d2a8-ce52-48e5-8d0c-0fdc46de3e3c","req_id":"637252072726597","op":"ping"}

        # 认证成功消息
        # {"req_id":"637267887005765","success":true,"ret_msg":"","op":"auth","conn_id":"ct7b5b9qo29o0l72ltjg-4r9wz"}
        # 订阅成功消息
        # {"req_id":"637293387100229","success":true,"ret_msg":"","op":"subscribe","conn_id":"ct7b5b9qo29o0l72ltjg-4rlxh"}

        # {"topic":"tickers.XRPUSDT","type":"snapshot","data":{"symbol":"XRPUSDT","tickDirection":"ZeroPlusTick","price24hPcnt":"0.027667","lastPrice":"3.3280","prevPrice24h":"3.2384","highPrice24h":"3.5682","lowPrice24h":"2.7435","prevPrice1h":"3.1172","markPrice":"3.2017","indexPrice":"3.1902","openInterest":"168321439","openInterestValue":"538914751.25","turnover24h":"1842287467.9510","volume24h":"587583919.0000","nextFundingTime":"1737734400000","fundingRate":"-0.00435","bid1Price":"3.3297","bid1Size":"4885","ask1Price":"3.3298","ask1Size":"1363","preOpenPrice":"","preQty":"","curPreListingPhase":""},"cs":19371556201,"ts":1737718426731}
        # {"topic":"tickers.XRPUSDT","type":"delta","data":{"symbol":"XRPUSDT","price24hPcnt":"0.028223","lastPrice":"3.3298","turnover24h":"1842288307.0604","volume24h":"587584171.0000","ask1Price":"3.3298","ask1Size":"1113"},"cs":19371556274,"ts":1737718429132}

        # 订单消息
        # {"topic":"order","id":"104183676_XRPUSDT_19371738695","creationTime":1737725795599,"data":[{"category":"linear","symbol":"XRPUSDT","orderId":"e09b7733-3df0-4684-b866-f5a802fb7ee2","orderLinkId":"","blockTradeId":"","side":"Buy","positionIdx":0,"orderStatus":"New","cancelType":"UNKNOWN","rejectReason":"EC_NoError","timeInForce":"GTC","isLeverage":"","price":"2.5293","qty":"10","avgPrice":"","leavesQty":"10","leavesValue":"25.293","cumExecQty":"0","cumExecValue":"0","cumExecFee":"0","orderType":"Limit","stopOrderType":"","orderIv":"","triggerPrice":"","takeProfit":"","stopLoss":"","triggerBy":"","tpTriggerBy":"","slTriggerBy":"","triggerDirection":0,"placeType":"","lastPriceOnCreated":"3.129","closeOnTrigger":false,"reduceOnly":false,"smpGroup":0,"smpType":"None","smpOrderId":"","slLimitPrice":"0","tpLimitPrice":"0","tpslMode":"UNKNOWN","createType":"CreateByUser","marketUnit":"","createdTime":"1737725795593","updatedTime":"1737725795596","feeCurrency":"","closedPnl":"0"}]}
        # 钱包消息
        # {"id":"104183676_wallet_1737725795606","topic":"wallet","creationTime":1737725795605,"data":[{"accountIMRate":"0.0043","accountMMRate":"0.0003","totalEquity":"1001.52819962","totalWalletBalance":"840.11430712","totalMarginBalance":"841.28368768","totalAvailableBalance":"837.6076437","totalPerpUPL":"1.16938055","totalInitialMargin":"3.67604398","totalMaintenanceMargin":"0.30525761","coin":[{"coin":"USDT","equity":"1001.44207561","usdValue":"1001.52819962","walletBalance":"1000.05007561","availableToWithdraw":"","availableToBorrow":"","borrowAmount":"0","accruedInterest":"0","totalOrderIM":"2.55573119","totalPositionIM":"1.11999668","totalPositionMM":"0.08910268","unrealisedPnl":"1.392","cumRealisedPnl":"0.05007561","bonus":"0","collateralSwitch":true,"marginCollateral":true,"locked":"0","spotHedgingQty":"0"}],"accountLTV":"0","accountType":"UNIFIED"}]}
        # 持仓消息
        # {"id":"104183676_position_1737725795606","topic":"position","creationTime":1737725795605,"data":[{"positionIdx":0,"tradeMode":0,"riskId":41,"riskLimitValue":"250000","symbol":"XRPUSDT","side":"Buy","size":"4","entryPrice":"2.7862","sessionAvgPrice":"","leverage":"10","positionValue":"11.1448","positionBalance":"0","markPrice":"3.1342","positionIM":"1.11999668","positionMM":"0.08910268","takeProfit":"0","stopLoss":"0","trailingStop":"0","unrealisedPnl":"1.392","cumRealisedPnl":"0.05007561","curRealisedPnl":"0.05007561","createdTime":"1737695187734","updatedTime":"1737705600059","tpslMode":"Full","liqPrice":"","bustPrice":"","category":"linear","positionStatus":"Normal","adlRankIndicator":2,"autoAddMargin":0,"leverageSysUpdatedTime":"","mmrSysUpdatedTime":"","seq":19371738695,"isReduceOnly":false}]}
        # 执行消息
        # {"topic":"execution","id":"104183676_XRPUSDT_19371741293","creationTime":1737725902960,"data":[{"category":"linear","symbol":"XRPUSDT","closedSize":"0","execFee":"0.00125696","execId":"ba509918-9526-5485-acbf-9dc2af25ae1e","execPrice":"3.1424","execQty":"1","execType":"Trade","execValue":"3.1424","feeRate":"0.0004","tradeIv":"","markIv":"","blockTradeId":"","markPrice":"3.1424","indexPrice":"","underlyingPrice":"","leavesQty":"9","orderId":"c7cffe92-d5e1-403a-9e8b-3cb3508f7dcc","orderLinkId":"","orderPrice":"3.2995","orderQty":"10","orderType":"Market","stopOrderType":"UNKNOWN","side":"Buy","execTime":"1737725902941","isLeverage":"0","isMaker":false,"seq":19371741293,"marketUnit":"","execPnl":"0","createType":"CreateByUser"},{"category":"linear","symbol":"XRPUSDT","closedSize":"0","execFee":"0.01131372","execId":"d382f1b7-fb96-5721-87da-ee475174bc19","execPrice":"3.1427","execQty":"9","execType":"Trade","execValue":"28.2843","feeRate":"0.0004","tradeIv":"","markIv":"","blockTradeId":"","markPrice":"3.1424","indexPrice":"","underlyingPrice":"","leavesQty":"0","orderId":"c7cffe92-d5e1-403a-9e8b-3cb3508f7dcc","orderLinkId":"","orderPrice":"3.2995","orderQty":"10","orderType":"Market","stopOrderType":"UNKNOWN","side":"Buy","execTime":"1737725902941","isLeverage":"0","isMaker":false,"seq":19371741293,"marketUnit":"","execPnl":"0","createType":"CreateByUser"}]}

        var json_obj = JsonObject(message)

        var topic = json_obj.get_str("topic")
        if topic == "order":
            self.__on_order(json_obj)
            return
        if topic == "wallet":
            self.__on_wallet(json_obj)
            return
        if topic == "position":
            self.__on_position(json_obj)
            return
        if topic == "execution":
            self.__on_execution(json_obj)
            return
        if topic.startswith("tickers."):
            self.__on_ticker(json_obj)
            return

        var op = json_obj.get_str("op")
        if op == "ping":
            logd("ping")
        elif op == "auth":
            var success = json_obj.get_bool("success")
            logd("success: " + str(success))
            if success:
                logi("WebSocket authentication successful")
                self._subscribe()
            else:
                logw("WebSocket authentication failed")

        _ = json_obj^

    @always_inline
    fn __on_ticker(self, json_obj: JsonObject) -> None:
        logd("__on_ticker")
        var data = json_obj.get_object_mut("data")
        """
        {
            "symbol": "XRPUSDT",
            "price24hPcnt": "0.028223",
            "lastPrice": "3.3298",
            "turnover24h": "1842288307.0604",
            "volume24h": "587584171.0000",
            "ask1Price": "3.3298",
            "ask1Size": "1113"
        }
        """
        var symbol = data.get_str("symbol")
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
        # {"topic":"order","id":"104183676_XRPUSDT_19371738695","creationTime":1737725795599,"data":[{"category":"linear","symbol":"XRPUSDT","orderId":"e09b7733-3df0-4684-b866-f5a802fb7ee2","orderLinkId":"","blockTradeId":"","side":"Buy","positionIdx":0,"orderStatus":"New","cancelType":"UNKNOWN","rejectReason":"EC_NoError","timeInForce":"GTC","isLeverage":"","price":"2.5293","qty":"10","avgPrice":"","leavesQty":"10","leavesValue":"25.293","cumExecQty":"0","cumExecValue":"0","cumExecFee":"0","orderType":"Limit","stopOrderType":"","orderIv":"","triggerPrice":"","takeProfit":"","stopLoss":"","triggerBy":"","tpTriggerBy":"","slTriggerBy":"","triggerDirection":0,"placeType":"","lastPriceOnCreated":"3.129","closeOnTrigger":false,"reduceOnly":false,"smpGroup":0,"smpType":"None","smpOrderId":"","slLimitPrice":"0","tpLimitPrice":"0","tpslMode":"UNKNOWN","createType":"CreateByUser","marketUnit":"","createdTime":"1737725795593","updatedTime":"1737725795596","feeCurrency":"","closedPnl":"0"}]}
        var data = json_obj.get_array_mut("data")
        for i in range(0, data.len()):
            var item = data.get(i)
            var item_view = JsonValueRefObjectView(item)
            """
            {
                "category": "linear",
                "symbol": "XRPUSDT",
                "orderId": "e09b7733-3df0-4684-b866-f5a802fb7ee2",
                "orderLinkId": "",
                "blockTradeId": "",
                "side": "Buy",
                "positionIdx": 0,
                "orderStatus": "New",
                "cancelType": "UNKNOWN",
                "rejectReason": "EC_NoError",
                "timeInForce": "GTC",
                "isLeverage": "",
                "price": "2.5293",
                "qty": "10",
                "avgPrice": "",
                "leavesQty": "10",
                "leavesValue": "25.293",
                "cumExecQty": "0",
                "cumExecValue": "0",
                "cumExecFee": "0",
                "orderType": "Limit",
                "stopOrderType": "",
                "orderIv": "",
                "triggerPrice": "",
                "takeProfit": "",
                "stopLoss": "",
                "triggerBy": "",
                "tpTriggerBy": "",
                "slTriggerBy": "",
                "triggerDirection": 0,
                "placeType": "",
                "lastPriceOnCreated": "3.129",
                "closeOnTrigger": false,
                "reduceOnly": false,
                "smpGroup": 0,
                "smpType": "None",
                "smpOrderId": "",
                "slLimitPrice": "0",
                "tpLimitPrice": "0",
                "tpslMode": "UNKNOWN",
                "createType": "CreateByUser",
                "marketUnit": "",
                "createdTime": "1737725795593",
                "updatedTime": "1737725795596",
                "feeCurrency": "",
                "closedPnl": "0"
            }
            """
            var order = Order()
            order.symbol = item_view.get_str("symbol")
            order.id = item_view.get_str("orderId")
            order.side = (
                OrderSide.Buy if item_view.get_str("side")
                == "Buy" else OrderSide.Sell
            )
            order.status = item_view.get_str("orderStatus")
            order.type = item_view.get_str("orderType")
            order.price = Fixed(item_view.get_str("price"))
            order.amount = Fixed(item_view.get_str("qty"))
            order.filled = Fixed(item_view.get_str("leavesQty"))
            try:
                order.timestamp = int(item_view.get_str("createdTime"))
            except e:
                logw("parse createdTime error: " + str(e))
            order.datetime = str(order.timestamp)
            if self._verbose:
                logd("order: " + str(order))
            self._on_order(self._trading_context, order)
        _ = data^

    @always_inline
    fn __on_wallet(self, json_obj: JsonObject) -> None:
        # {"id":"104183676_wallet_1737725795606","topic":"wallet","creationTime":1737725795605,"data":[{"accountIMRate":"0.0043","accountMMRate":"0.0003","totalEquity":"1001.52819962","totalWalletBalance":"840.11430712","totalMarginBalance":"841.28368768","totalAvailableBalance":"837.6076437","totalPerpUPL":"1.16938055","totalInitialMargin":"3.67604398","totalMaintenanceMargin":"0.30525761","coin":[{"coin":"USDT","equity":"1001.44207561","usdValue":"1001.52819962","walletBalance":"1000.05007561","availableToWithdraw":"","availableToBorrow":"","borrowAmount":"0","accruedInterest":"0","totalOrderIM":"2.55573119","totalPositionIM":"1.11999668","totalPositionMM":"0.08910268","unrealisedPnl":"1.392","cumRealisedPnl":"0.05007561","bonus":"0","collateralSwitch":true,"marginCollateral":true,"locked":"0","spotHedgingQty":"0"}],"accountLTV":"0","accountType":"UNIFIED"}]}
        var data = json_obj.get_array_mut("data")
        for i in range(data.len()):
            pass
            # var item = data.get(i)
            # var item_view = JsonValueRefObjectView(item)
            """
            {
                "accountIMRate": "0.0043",
                "accountMMRate": "0.0003",
                "totalEquity": "1001.52819962",
                "totalWalletBalance": "840.11430712",
                "totalMarginBalance": "841.28368768",
                "totalAvailableBalance": "837.6076437",
                "totalPerpUPL": "1.16938055",
                "totalInitialMargin": "3.67604398",
                "totalMaintenanceMargin": "0.30525761",
                "coin": [{
                        "coin": "USDT",
                        "equity": "1001.44207561",
                        "usdValue": "1001.52819962",
                        "walletBalance": "1000.05007561",
                        "availableToWithdraw": "",
                        "availableToBorrow": "",
                        "borrowAmount": "0",
                        "accruedInterest": "0",
                        "totalOrderIM": "2.55573119",
                        "totalPositionIM": "1.11999668",
                        "totalPositionMM": "0.08910268",
                        "unrealisedPnl": "1.392",
                        "cumRealisedPnl": "0.05007561",
                        "bonus": "0",
                        "collateralSwitch": true,
                        "marginCollateral": true,
                        "locked": "0",
                        "spotHedgingQty": "0"
                    }
                ],
                "accountLTV": "0",
                "accountType": "UNIFIED"
            }
            """
            # TODO:
        _ = data^

    @always_inline
    fn __on_position(self, json_obj: JsonObject) -> None:
        pass

    @always_inline
    fn __on_execution(self, json_obj: JsonObject) -> None:
        pass

    fn __on_ping(self) -> None:
        logd("__on_ping")

    fn __on_error(self, error: String) -> None:
        logd("__on_error: " + error)

    fn __on_close(self) -> None:
        logd("__on_close")

    fn __on_timer(mut self, count: UInt64) -> None:
        logd("__on_timer")
        self._ping()

    fn _ping(mut self) -> None:
        var id = idgen_next_id()

        var o = JsonObject()
        o.insert_str("req_id", str(id))
        o.insert_str("op", "ping")
        var body_str = o.to_string()
        if self._verbose:
            logd("send: " + body_str)
        # {"req_id":"637252072726597","op":"ping"}
        _ = self._ws[].send(body_str)

    fn subscribe_ticker(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # 推送頻率: 期貨和期權 - 100ms, 現貨 - 實時
        # tickers.{symbol}
        var topic = String.format("tickers.{}", symbol)
        self._subscription_topics.append(topic)

    fn subscribe_tickers(
        mut self, symbols: Strings, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe_order_book(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # orderbook.{depth}.{symbol} e.g., orderbook.1.BTCUSDT
        var depth = params.get("depth", 1).int()
        var topic = String.format("orderbook.{}.{}", depth, symbol)
        self._subscription_topics.append(topic)

    fn subscribe_trade(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        pass

    fn subscribe_balance(mut self, params: Dict[String, Any]) raises -> None:
        self._subscription_topics.append("wallet")
        self._subscription_topics.append("position")

    fn subscribe_order(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        self._subscription_topics.append("order")

    fn subscribe_my_trades(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        # execution.fast
        self._subscription_topics.append("execution")

    fn _subscribe(mut self) -> None:
        if len(self._subscription_topics) == 0:
            return

        var id = idgen_next_id()
        var o = JsonObject()
        o.insert_str("req_id", str(id))
        o.insert_str("op", "subscribe")
        var args = JsonArray()
        for topic in self._subscription_topics:
            args.push_str(topic[])
        o.insert_array("args", args)
        var body_str = o.to_string()
        logd("send: " + body_str)
        _ = self._ws[].send(body_str)

    fn generate_auth_payload(self) -> String:
        var expires = str(int(now_ms() + 5000))
        var req: String = "GET/realtime" + expires
        var hex_signature = compute_hmac_sha256_hex(req, self._api_secret)

        var id = idgen_next_id()
        var o = JsonObject()
        o.insert_str("req_id", str(id))
        o.insert_str("op", "auth")
        var args = JsonArray()
        args.push_str(self._api_key)
        args.push_str(expires)
        args.push_str(hex_signature)
        o.insert_array("args", args)
        var s = o.to_string()
        return s
