from memory import UnsafePointer, stack_allocation
from monoio_connect import (
    logt,
    logd,
    logi,
    logw,
    Fixed,
    now_ms,
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
    HttpResponseCallback,
    QueryStringBuilder,
)
from ccxt.base.types import *
from ccxt.base.exchangeable import Exchangeable
from ccxt.abstract.bybit import ImplicitAPI
from sonic import *
from ._common_utils import *


fn empty_on_order(trading_context: TradingContext, order: Order) -> None:
    pass


struct Bybit(Exchangeable):
    var _client: UnsafePointer[HttpClient]
    var _api: ImplicitAPI
    var _api_key: String
    var _api_secret: String
    var _on_order: UnsafePointer[OnOrderC]
    var _trading_context: TradingContext
    var _host: String
    var _testnet: Bool
    var _verbose: Bool
    var _category: String

    fn __init__(
        out self,
        config: Dict[String, Any],
        trading_context: TradingContext,
        rt: MonoioRuntimePtr = MonoioRuntimePtr(),
    ):
        self._testnet = config.get("testnet", False).bool()
        self._verbose = config.get("verbose", False).bool()
        # https://api.bybit.com
        # https://api.bytick.com
        var base_url: String = "https://api.bybit.com" if not self._testnet else "https://api-testnet.bybit.com"
        var _base_url = config.get("base_url", "").string()
        if len(_base_url) > 0:
            base_url = _base_url
        self._trading_context = trading_context
        self._host = String(base_url).replace("https://", "")
        var options = HttpClientOptions(base_url)
        self._client = UnsafePointer[HttpClient].alloc(1)
        __get_address_as_uninit_lvalue(self._client.address) = HttpClient(
            options, rt, self._verbose
        )
        self._api = ImplicitAPI()
        self._api_key = str(config.get("api_key", String()))
        self._api_secret = str(config.get("api_secret", String()))
        self._on_order = UnsafePointer[OnOrderC].alloc(1)
        self._category = "linear"

    fn __del__(owned self):
        self._client.destroy_pointee()
        self._client.free()

    fn __moveinit__(out self, owned other: Self):
        self._host = other._host
        self._client = other._client
        other._client = UnsafePointer[HttpClient]()
        self._api = other._api^
        self._api_key = other._api_key
        self._api_secret = other._api_secret
        self._on_order = other._on_order
        self._trading_context = other._trading_context
        self._testnet = other._testnet
        self._verbose = other._verbose
        self._category = other._category

    fn id(self) -> ExchangeId:
        return ExchangeId.bybit

    fn set_on_order(mut self, on_order: OnOrderC) -> None:
        self._on_order.init_pointee_move(on_order)

    @always_inline
    fn _request(
        self,
        entry: Entry,
        params: Dict[String, Any],
        query: String,
        payload: String,
    ) raises -> String:
        # logd("entry: " + entry.path)
        return self._request(
            entry.method, "/" + entry.path, params, query, payload, entry.api
        )

    @always_inline
    fn _request(
        self,
        method: Method,
        path: String,
        params: Dict[String, Any],
        query: String,
        payload: String,
        api: ApiType = ApiType.Public,
    ) raises -> String:
        # logd("entry: " + str(method) + " " + path)
        var full_path = path
        var headers = Headers()

        # headers["Accept"] = "application/json"
        # headers["Content-Type"] = "application/json"
        headers["host"] = self._host
        headers["user-agent"] = "monoio-http"
        headers["content-type"] = "application/json"
        headers["accept-encoding"] = "gzip, deflate"

        if api == ApiType.Private:
            if method == Method.METHOD_GET:
                self._sign(headers, query)
            elif method == Method.METHOD_POST:
                self._sign(headers, payload)
        if query != "":
            full_path += "?" + query

        var response = self._client[].request(
            full_path, method, headers, payload
        )
        # {"retCode":10003,"retMsg":"API key is invalid.","result":{},"retExtInfo":{},"time":1737599375944}
        if response.status_code == 0:
            raise Error("HTTP status code: " + str(response.status_code))
        if response.status_code >= 200 and response.status_code < 300:
            return response.text
        elif response.status_code >= 400 and response.status_code < 500:
            logt("response.text: " + response.text)
            if response.text.startswith("{") and response.text.endswith("}"):
                # var doc = JsonObject(response.text)
                # var code = doc.get_i64("code")
                # var message = doc.get_str("msg")
                # raise Error(label + ": " + message)
                return response.text
            else:
                # raise Error("HTTP status code: " + str(response.status_code))
                return response.text
        return response.text

    @always_inline
    fn _request_with_callback(
        self,
        entry: Entry,
        params: Dict[String, Any],
        query: String,
        payload: String,
        callback: HttpResponseCallback = _request_callback,
    ) raises -> None:
        # logd("entry: " + entry.path)
        self._request_with_callback(
            entry.method,
            entry.path,
            params,
            query,
            payload,
            entry.api,
            callback,
        )

    @always_inline
    fn _request_with_callback(
        self,
        method: Method,
        path: String,
        params: Dict[String, Any],
        query: String,
        payload: String,
        api: ApiType = ApiType.Public,
        callback: HttpResponseCallback = _request_callback,
    ) raises -> None:
        var full_path = path
        var headers = Headers()

        # headers["Accept"] = "application/json"
        # headers["Content-Type"] = "application/json"
        headers["host"] = self._host
        headers["user-agent"] = "monoio-http"
        headers["content-type"] = "application/json"
        headers["accept-encoding"] = "gzip, deflate"

        if api == ApiType.Private:
            self._sign(headers, query)
        if query != "":
            full_path += "?" + query

        # var response = self._client[].request(
        #     full_path, method, headers, payload
        # )
        self._client[].request_with_callback(
            full_path, method, headers, payload, 0, callback
        )

    @always_inline
    fn _sign(self, mut headers: Headers, data: String) raises:
        var time_ms_str = str(int(now_ms()))
        # logi("time_ms_str=" + time_ms_str)
        var recv_window_str = "15000"
        # logd("do_sign: " + data)
        # var payload = data
        # logd("do_sign: " + data)
        var param_str = time_ms_str + self._api_key + recv_window_str + data
        var sign_str = compute_hmac_sha256_hex(param_str, self._api_secret)
        headers["X-BAPI-API-KEY"] = self._api_key
        headers["X-BAPI-TIMESTAMP"] = time_ms_str
        headers["X-BAPI-SIGN"] = sign_str
        headers["X-BAPI-RECV-WINDOW"] = recv_window_str

    fn load_markets(self, mut params: Dict[String, Any]) raises -> List[Market]:
        raise Error("NotImplemented")

    fn fetch_markets(
        self, mut params: Dict[String, Any]
    ) raises -> List[Market]:
        # responseInner = await self.privateGetV5MarketInstrumentsInfo(params)
        # responseInner = await self.publicGetV5MarketInstrumentsInfo(params)
        var query_values = QueryStringBuilder()
        query_values["category"] = self._category
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_market_instruments_info, params, query_str, ""
        )
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = List[Market]()
        var result = doc.get_object_mut("result")
        var list = result.get_array_mut("list")
        for i in range(0, list.len()):
            var row = list.get(i)
            var row_view = JsonValueRefObjectView(row)
            """
            {
                "symbol": "10000000AIDOGEUSDT",
                "contractType": "LinearPerpetual",
                "status": "Trading",
                "baseCoin": "10000000AIDOGE",
                "quoteCoin": "USDT",
                "launchTime": "1709542899000",
                "deliveryTime": "0",
                "deliveryFeeRate": "",
                "priceScale": "6",
                "leverageFilter": {
                    "minLeverage": "1",
                    "maxLeverage": "12.50",
                    "leverageStep": "0.01"
                },
                "priceFilter": {
                    "minPrice": "0.000001",
                    "maxPrice": "19.999998",
                    "tickSize": "0.000001"
                },
                "lotSizeFilter": {
                    "maxOrderQty": "15000000",
                    "minOrderQty": "100",
                    "qtyStep": "100",
                    "postOnlyMaxOrderQty": "15000000",
                    "maxMktOrderQty": "3000000",
                    "minNotionalValue": "5"
                },
                "unifiedMarginTrade": true,
                "fundingInterval": 480,
                "settleCoin": "USDT",
                "copyTrading": "none",
                "upperFundingRate": "0.03",
                "lowerFundingRate": "-0.03",
                "isPreListing": false,
                "preListingInfo": null,
                "riskParameters": {
                    "priceLimitRatioX": "0.05",
                    "priceLimitRatioY": "0.1"
                }
            }
            """
            var market = MarketInterface()
            market.symbol = row_view.get_str("symbol")
            market.base = row_view.get_str("baseCoin")
            market.quote = row_view.get_str("quoteCoin")
            market.spot = False
            market.margin = False
            market.swap = True
            market.future = False
            market.type = String("swap")
            market.subType = String("swap")
            market.active = row_view.get_str("status") == "Trading"
            var lotSizeFilter = row_view.get_value("lotSizeFilter")
            var lsf = JsonValueObjectView(lotSizeFilter)
            var qtyStep = lsf.get_str("qtyStep")
            market.contractSize = Fixed(qtyStep)
            logd("qtyStep: " + qtyStep)
            var priceFilter = row_view.get_value("priceFilter")
            var pf = JsonValueObjectView(priceFilter)
            var tickSize = pf.get_str("tickSize")
            logd("tickSize: " + tickSize)
            res.append(market)
        _ = list^
        _ = result^
        _ = doc^
        return res

    fn fetch_currencies(
        self, mut params: Dict[String, Any]
    ) raises -> List[Currency]:
        var query_values = QueryStringBuilder()
        var coin = params.get("coin", String("")).string()
        if coin != "":
            query_values["coin"] = coin
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_asset_coin_query_info, params, query_str, ""
        )
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = List[Currency]()
        var result = doc.get_object_mut("result")
        var rows = result.get_array_mut("rows")
        for i in range(0, rows.len()):
            var row = rows.get(i)
            var row_view = JsonValueRefObjectView(row)
            """
            {
                "name": "AAVE",
                "coin": "AAVE",
                "remainAmount": "0",
                "chains": [{
                        "chainType": "Ethereum",
                        "confirmation": "12",
                        "withdrawFee": "0",
                        "depositMin": "0",
                        "withdrawMin": "0",
                        "chain": "ETH",
                        "chainDeposit": "0",
                        "chainWithdraw": "1",
                        "minAccuracy": "8",
                        "withdrawPercentageFee": "0",
                        "contractAddress": "0xd989df310cf6b0238dd4a993bfb29c40410f294f"
                    }
                ]
            }
            """
            var name = row_view.get_str("name")
            var coin = row_view.get_str("coin")
            var currency = CurrencyInterface()
            currency.id = name
            currency.code = coin
            currency.active = True
            # currency.precision = Fixed(8)
            currency.fee = Fixed(0)
            # currency.withdraw_min = Fixed(0)
            # currency.withdraw_fee = Fixed(0)
            # currency.deposit_fee = Fixed(0)
            res.append(currency)
        _ = rows^
        _ = result^
        _ = doc^
        return res

    fn fetch_ticker(self, symbol: String) raises -> Ticker:
        var query_values = QueryStringBuilder()
        query_values["category"] = self._category
        query_values["symbol"] = symbol
        var query_str = query_values.to_string()
        var params = Dict[String, Any]()
        var text = self._request(
            self._api.v5_market_tickers, params, query_str, ""
        )
        # {"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"XRPUSDT","lastPrice":"3.1694","indexPrice":"3.0618","markPrice":"3.1465","prevPrice24h":"3.1789","price24hPcnt":"-0.002988","highPrice24h":"3.5914","lowPrice24h":"2.7633","prevPrice1h":"3.0176","openInterest":"173487153","openInterestValue":"545877326.91","turnover24h":"1135772933.1616","volume24h":"361057945.0000","fundingRate":"-0.00162807","nextFundingTime":"1737648000000","predictedDeliveryPrice":"","basisRate":"","deliveryFeeRate":"","deliveryTime":"0","ask1Size":"3","bid1Price":"3.1694","ask1Price":"3.1744","bid1Size":"11939","basis":"","preOpenPrice":"","preQty":"","curPreListingPhase":""}]},"retExtInfo":{},"time":1737636114769}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = Ticker()
        var result = doc.get_object_mut("result")
        var list = result.get_array_mut("list")
        for i in range(list.len()):
            var row = list.get(i)
            """
            {
                "symbol": "XRPUSDT",
                "lastPrice": "3.1694",
                "indexPrice": "3.0618",
                "markPrice": "3.1465",
                "prevPrice24h": "3.1789",
                "price24hPcnt": "-0.002988",
                "highPrice24h": "3.5914",
                "lowPrice24h": "2.7633",
                "prevPrice1h": "3.0176",
                "openInterest": "173487153",
                "openInterestValue": "545877326.91",
                "turnover24h": "1135772933.1616",
                "volume24h": "361057945.0000",
                "fundingRate": "-0.00162807",
                "nextFundingTime": "1737648000000",
                "predictedDeliveryPrice": "",
                "basisRate": "",
                "deliveryFeeRate": "",
                "deliveryTime": "0",
                "ask1Size": "3",
                "bid1Price": "3.1694",
                "ask1Price": "3.1744",
                "bid1Size": "11939",
                "basis": "",
                "preOpenPrice": "",
                "preQty": "",
                "curPreListingPhase": ""
            }
            """
            var row_view = JsonValueRefObjectView(row)
            var symbol_ = row_view.get_str("symbol")
            if symbol_ == symbol:
                res.open = Fixed(0)
                res.high = Fixed(row_view.get_str("highPrice24h"))
                res.low = Fixed(row_view.get_str("lowPrice24h"))
                res.ask = Fixed(row_view.get_str("ask1Price"))
                res.askVolume = Fixed(row_view.get_str("ask1Size"))
                res.bid = Fixed(row_view.get_str("bid1Price"))
                res.bidVolume = Fixed(row_view.get_str("bid1Size"))
                break
        _ = list^
        _ = result^
        _ = doc^
        return res

    fn fetch_tickers(
        self, symbols: Strings, mut params: Dict[String, Any]
    ) raises -> List[Ticker]:
        raise Error("NotImplemented")

    fn fetch_order_book(
        self, symbol: String, limit: IntOpt, mut params: Dict[String, Any]
    ) raises -> OrderBook:
        var query_values = QueryStringBuilder()
        query_values["category"] = self._category
        query_values["symbol"] = symbol
        if limit:
            query_values["limit"] = str(limit.value())
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_market_orderbook, params, query_str, ""
        )
        # {"retCode":0,"retMsg":"OK","result":{"s":"XRPUSDT","b":[["3.1681","4906"],["3.168","15442"],["3.1679","16369"],["3.1678","12790"],["3.1677","16387"],["3.1676","10551"],["3.1648","3"],["3.1616","3"],["3.1584","3"],["3.1552","3"]],"a":[["3.1683","1457"],["3.1684","1465"],["3.1685","986"],["3.1686","1287"],["3.1687","1269"],["3.1688","1505"],["3.1689","1062"],["3.169","1043"],["3.1712","3"],["3.1722","1"]],"ts":1737637125960,"u":481115,"seq":19369631982,"cts":1737637125675},"retExtInfo":{},"time":1737637126066}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = OrderBook()
        var result = doc.get_object_mut("result")
        var symbol_ = result.get_str("s")
        if symbol != symbol_:
            raise Error("symbol error: " + symbol_)
        var b = result.get_array_mut("b")
        for i in range(b.len()):
            var row = b.get(i)
            var row_view = JsonValueRefArrayView(row)
            var bid = Fixed(row_view.get_str(0, "0"))
            var bid_size = Fixed(row_view.get_str(1, "0"))
            res.bids.append(OrderbookEntry(bid, bid_size))
        var a = result.get_array_mut("a")
        for i in range(a.len()):
            var row = a.get(i)
            var row_view = JsonValueRefArrayView(row)
            var ask = Fixed(row_view.get_str(0, "0"))
            var ask_size = Fixed(row_view.get_str(1, "0"))
            res.asks.append(OrderbookEntry(ask, ask_size))
        _ = result^
        _ = doc^
        return res

    # fn fetch_ohlcv(self, symbol: String, timeframe: String, since: Int, limit: Int) -> List[OHLCV]:
    #     ...

    # fn fetch_status(self) -> Status:
    #     ...

    fn fetch_trades(
        self,
        symbol: String,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        raise Error("NotImplemented")

    fn fetch_balance(self, mut params: Dict[String, Any]) raises -> Balances:
        """Query for balance.

        https://bybit-exchange.github.io/docs/zh-TW/v5/account/wallet-balance.
        """
        var query_values = QueryStringBuilder()
        query_values["accountType"] = "UNIFIED"
        # query_values["coin"] = "USDT,USDC"
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_account_wallet_balance, params, query_str, ""
        )
        # {"retCode":0,"retMsg":"OK","result":{"list":[{"totalEquity":"999.729","accountIMRate":"0","totalMarginBalance":"839.77236","totalInitialMargin":"0","accountType":"UNIFIED","totalAvailableBalance":"839.77236","accountMMRate":"0","totalPerpUPL":"0","totalWalletBalance":"839.77236","accountLTV":"0","totalMaintenanceMargin":"0","coin":[{"availableToBorrow":"","bonus":"0","accruedInterest":"0","availableToWithdraw":"","totalOrderIM":"0","equity":"1000","totalPositionMM":"0","usdValue":"999.729","unrealisedPnl":"0","collateralSwitch":true,"spotHedgingQty":"0","borrowAmount":"0.000000000000000000","totalPositionIM":"0","walletBalance":"1000","cumRealisedPnl":"0","locked":"0","marginCollateral":true,"coin":"USDT"}]}]},"retExtInfo":{},"time":1737640902711}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        # var res = List[Currency]()
        # var result = doc.get_object_mut("result")
        # var rows = result.get_array_mut("rows")
        var res = Balances()
        var result = doc.get_object_mut("result")
        var list = result.get_array_mut("list")
        for i in range(list.len()):
            var row = list.get(i)
            var row_view = JsonValueRefObjectView(row)
            var coin = row_view.get_array_ref("coin")
            for j in range(coin.len()):
                var coin_row = coin.get(j)
                var coin_row_view = JsonValueRefObjectView(coin_row)
                var coin_name = coin_row_view.get_str("coin")
                """
                {
                        "availableToBorrow": "",
                        "bonus": "0",
                        "accruedInterest": "0",
                        "availableToWithdraw": "",
                        "totalOrderIM": "0",
                        "equity": "1000",
                        "totalPositionMM": "0",
                        "usdValue": "999.729",
                        "unrealisedPnl": "0",
                        "collateralSwitch": true,
                        "spotHedgingQty": "0",
                        "borrowAmount": "0.000000000000000000",
                        "totalPositionIM": "0",
                        "walletBalance": "1000",
                        "cumRealisedPnl": "0",
                        "locked": "0",
                        "marginCollateral": true,
                        "coin": "USDT"
                    }
                """
                var balance = Balance()
                balance.total = Fixed(coin_row_view.get_str("equity"))
                balance.used = Fixed(coin_row_view.get_str("locked"))
                balance.free = balance.total - balance.used
                res.data[coin_name] = balance
        _ = result^
        _ = doc^
        return res

    fn create_order(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> Order:
        var post_doc = JsonObject()
        post_doc.insert_str("category", self._category)
        post_doc.insert_str("symbol", symbol)
        post_doc.insert_str(
            "side", "Buy" if side == OrderSide.Buy else "Sell"
        )  # Buy, Sell
        post_doc.insert_str(
            "orderType", "Market" if type == OrderType.Market else "Limit"
        )  # Market, Limit
        post_doc.insert_str("qty", str(amount))
        if price != Fixed.zero:
            post_doc.insert_str("price", str(price))
        var time_in_force = params.get("time_in_force", String("")).string()
        if time_in_force != "":
            post_doc.insert_str("timeInForce", time_in_force)
        var position_idx = params.get("position_idx", 0).int()
        if position_idx != 0:
            post_doc.insert_str("positionIdx", str(position_idx))
        var order_link_id = params.get("client_order_id", String("")).string()
        if order_link_id != "":
            post_doc.insert_str("orderLinkId", order_link_id)
        var reduce_only = params.get("reduce_only", False).bool()
        if reduce_only:
            post_doc.insert_str("reduceOnly", "true")
        var is_leverage = params.get("is_leverage", -1).int()
        if is_leverage != -1:
            post_doc.insert_i64("isLeverage", is_leverage)
        var body_str = post_doc.to_string()
        var text = self._request(
            self._api.v5_order_create, params, "", body_str
        )
        # {"retCode":0,"retMsg":"OK","result":{"orderId":"d8612fcb-0565-4f39-9211-ebca8c25eb21","orderLinkId":""},"retExtInfo":{},"time":1737695187735}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = Order()
        var result = doc.get_object_mut("result")
        res.symbol = symbol
        res.id = result.get_str("orderId")
        res.clientOrderId = result.get_str("orderLinkId")
        res.side = side
        res.type = str(type)
        res.status = "New"
        _ = result^
        _ = doc^
        return res

    fn cancel_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        if not symbol:
            raise Error("param error")

        var post_doc = JsonObject()
        post_doc.insert_str("category", self._category)
        post_doc.insert_str("symbol", symbol.value())
        post_doc.insert_str("orderId", id)
        var body_str = post_doc.to_string()
        var text = self._request(
            self._api.v5_order_cancel, params, "", body_str
        )
        # {"retCode":0,"retMsg":"OK","result":{"orderId":"d7cae7eb-3c98-4116-85a8-b5857c226a8b","orderLinkId":""},"retExtInfo":{},"time":1737695925790}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = Order()
        var result = doc.get_object_mut("result")
        res.symbol = symbol.value()
        res.id = result.get_str("orderId")
        res.clientOrderId = result.get_str("orderLinkId")
        _ = result^
        _ = doc^
        return res

    fn fetch_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        # https://bybit-exchange.github.io/docs/zh-TW/v5/order/open-order
        var query_values = QueryStringBuilder()
        query_values["category"] = self._category
        if symbol:
            query_values["symbol"] = symbol.value()
        # baseCoin
        # settleCoin
        query_values["orderId"] = id
        # orderLinkId
        # openOnly
        # orderFilter
        # limit
        # cursor
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_order_realtime, params, query_str, ""
        )
        # {"retCode":0,"retMsg":"OK","result":{"nextPageCursor":"d7cae7eb-3c98-4116-85a8-b5857c226a8b%3A1737695479611%2Cd7cae7eb-3c98-4116-85a8-b5857c226a8b%3A1737695479611","category":"linear","list":[{"symbol":"XRPUSDT","orderType":"Limit","orderLinkId":"","slLimitPrice":"0","orderId":"d7cae7eb-3c98-4116-85a8-b5857c226a8b","cancelType":"CancelByUser","avgPrice":"","stopOrderType":"","lastPriceOnCreated":"3.1661","orderStatus":"Cancelled","createType":"CreateByUser","takeProfit":"","cumExecValue":"0","tpslMode":"","smpType":"None","triggerDirection":0,"blockTradeId":"","isLeverage":"","rejectReason":"EC_PerCancelRequest","price":"2.7862","orderIv":"","createdTime":"1737695479611","tpTriggerBy":"","positionIdx":0,"timeInForce":"GTC","leavesValue":"","updatedTime":"1737695925793","side":"Buy","smpGroup":0,"triggerPrice":"","tpLimitPrice":"0","cumExecFee":"0","leavesQty":"","slTriggerBy":"","closeOnTrigger":false,"placeType":"","cumExecQty":"0","reduceOnly":false,"qty":"4","stopLoss":"","marketUnit":"","smpOrderId":"","triggerBy":""}]},"retExtInfo":{},"time":1737696307843}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var result = doc.get_object_mut("result")
        var list = result.get_array_mut("list")
        for i in range(list.len()):
            var row = list.get(i)
            var row_view = JsonValueRefObjectView(row)
            if row_view.get_str("orderId") == id:
                return self._parse_order(row_view)
        _ = list^
        _ = result^
        raise Error("order not found")

    fn _parse_order[T: JsonObjectViewable](self, row_view: T) -> Order:
        """
        {
            "symbol": "XRPUSDT",
            "orderType": "Limit",
            "orderLinkId": "",
            "slLimitPrice": "0",
            "orderId": "d7cae7eb-3c98-4116-85a8-b5857c226a8b",
            "cancelType": "CancelByUser",
            "avgPrice": "",
            "stopOrderType": "",
            "lastPriceOnCreated": "3.1661",
            "orderStatus": "Cancelled",
            "createType": "CreateByUser",
            "takeProfit": "",
            "cumExecValue": "0",
            "tpslMode": "",
            "smpType": "None",
            "triggerDirection": 0,
            "blockTradeId": "",
            "isLeverage": "",
            "rejectReason": "EC_PerCancelRequest",
            "price": "2.7862",
            "orderIv": "",
            "createdTime": "1737695479611",
            "tpTriggerBy": "",
            "positionIdx": 0,
            "timeInForce": "GTC",
            "leavesValue": "",
            "updatedTime": "1737695925793",
            "side": "Buy",
            "smpGroup": 0,
            "triggerPrice": "",
            "tpLimitPrice": "0",
            "cumExecFee": "0",
            "leavesQty": "",
            "slTriggerBy": "",
            "closeOnTrigger": false,
            "placeType": "",
            "cumExecQty": "0",
            "reduceOnly": false,
            "qty": "4",
            "stopLoss": "",
            "marketUnit": "",
            "smpOrderId": "",
            "triggerBy": ""
        }
        """
        var res = Order()
        res.symbol = row_view.get_str("symbol")
        res.id = row_view.get_str("orderId")
        res.clientOrderId = row_view.get_str("orderLinkId")
        res.side = (
            OrderSide.Buy if row_view.get_str("side")
            == "Buy" else OrderSide.Sell
        )
        res.type = row_view.get_str("orderType")
        res.status = row_view.get_str("orderStatus")
        res.amount = Fixed(row_view.get_str("qty"))
        res.price = Fixed(row_view.get_str("price"))
        res.average = Fixed(row_view.get_str("avgPrice"))
        res.filled = Fixed(row_view.get_str("cumExecQty"))
        res.remaining = res.amount - res.filled
        res.cost = res.filled * res.average
        # res.fee = Fixed(row_view.get_str("cumExecFee"))
        # res.created = row_view.get_str("createdTime")
        # res.updated = row_view.get_str("updatedTime")
        return res

    fn fetch_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        # https://bybit-exchange.github.io/docs/zh-TW/v5/order/order-list
        var query_values = QueryStringBuilder()
        query_values["category"] = self._category
        if symbol:
            query_values["symbol"] = symbol.value()
        # baseCoin
        # settleCoin
        # orderId
        # orderLinkId
        # orderFilter
        # orderStatus
        # startTime
        # endTime
        # limit
        # cursor
        if since:
            query_values["startTime"] = str(since.value())  # 毫秒
        if limit:
            query_values["limit"] = str(limit.value())
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_order_history, params, query_str, ""
        )
        # {"retCode":0,"retMsg":"OK","result":{"nextPageCursor":"d7cae7eb-3c98-4116-85a8-b5857c226a8b%3A1737695479611%2Cd7cae7eb-3c98-4116-85a8-b5857c226a8b%3A1737695479611","category":"linear","list":[{"symbol":"XRPUSDT","orderType":"Limit","orderLinkId":"","slLimitPrice":"0","orderId":"d7cae7eb-3c98-4116-85a8-b5857c226a8b","cancelType":"CancelByUser","avgPrice":"","stopOrderType":"","lastPriceOnCreated":"3.1661","orderStatus":"Cancelled","createType":"CreateByUser","takeProfit":"","cumExecValue":"0","tpslMode":"","smpType":"None","triggerDirection":0,"blockTradeId":"","isLeverage":"","rejectReason":"EC_PerCancelRequest","price":"2.7862","orderIv":"","createdTime":"1737695479611","tpTriggerBy":"","positionIdx":0,"timeInForce":"GTC","leavesValue":"","updatedTime":"1737695925793","side":"Buy","smpGroup":0,"triggerPrice":"","tpLimitPrice":"0","cumExecFee":"0","leavesQty":"","slTriggerBy":"","closeOnTrigger":false,"placeType":"","cumExecQty":"0","reduceOnly":false,"qty":"4","stopLoss":"","marketUnit":"","smpOrderId":"","triggerBy":""}]},"retExtInfo":{},"time":1737696307843}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = List[Order]()
        var result = doc.get_object_mut("result")
        var list = result.get_array_mut("list")
        for i in range(list.len()):
            var row = list.get(i)
            var row_view = JsonValueRefObjectView(row)
            res.append(self._parse_order(row_view))
        _ = list^
        _ = result^
        _ = doc^
        return res

    fn fetch_open_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        var query_values = QueryStringBuilder()
        query_values["category"] = self._category
        if symbol:
            query_values["symbol"] = symbol.value()
        # baseCoin
        # settleCoin
        # orderId
        # orderLinkId
        # openOnly
        # orderFilter
        # orderStatus
        # startTime
        # endTime
        # limit
        # cursor
        var query_str = query_values.to_string()
        var text = self._request(
            self._api.v5_order_realtime, params, query_str, ""
        )
        # {"retCode":0,"retMsg":"OK","result":{"nextPageCursor":"d7cae7eb-3c98-4116-85a8-b5857c226a8b%3A1737695479611%2Cd7cae7eb-3c98-4116-85a8-b5857c226a8b%3A1737695479611","category":"linear","list":[{"symbol":"XRPUSDT","orderType":"Limit","orderLinkId":"","slLimitPrice":"0","orderId":"d7cae7eb-3c98-4116-85a8-b5857c226a8b","cancelType":"CancelByUser","avgPrice":"","stopOrderType":"","lastPriceOnCreated":"3.1661","orderStatus":"Cancelled","createType":"CreateByUser","takeProfit":"","cumExecValue":"0","tpslMode":"","smpType":"None","triggerDirection":0,"blockTradeId":"","isLeverage":"","rejectReason":"EC_PerCancelRequest","price":"2.7862","orderIv":"","createdTime":"1737695479611","tpTriggerBy":"","positionIdx":0,"timeInForce":"GTC","leavesValue":"","updatedTime":"1737695925793","side":"Buy","smpGroup":0,"triggerPrice":"","tpLimitPrice":"0","cumExecFee":"0","leavesQty":"","slTriggerBy":"","closeOnTrigger":false,"placeType":"","cumExecQty":"0","reduceOnly":false,"qty":"4","stopLoss":"","marketUnit":"","smpOrderId":"","triggerBy":""}]},"retExtInfo":{},"time":1737696307843}
        var doc = JsonObject(text)
        var ret_code = doc.get_i64("retCode")
        if ret_code != 0:
            var ret_msg = doc.get_str("retMsg")
            raise Error(ret_msg)

        var res = List[Order]()
        var result = doc.get_object_mut("result")
        var list = result.get_array_mut("list")
        for i in range(list.len()):
            var row = list.get(i)
            var row_view = JsonValueRefObjectView(row)
            res.append(self._parse_order(row_view))
        _ = list^
        _ = result^
        _ = doc^
        return res

    fn fetch_closed_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        raise Error("NotImplemented")

    fn fetch_my_trades(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        raise Error("NotImplemented")

    fn create_order_async(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> None:
        var request = AsyncTradingRequest(
            type=0,
            data=CreateOrderRequestData(
                symbol=symbol,
                order_type=type,
                order_side=side,
                amount=amount,
                price=price,
            ),
            exchange=UnsafePointer.address_of(self),
        )
        _ = async_trading_channel_ptr()[].send(request)

    fn cancel_order_async(
        self, id: String, symbol: String, mut params: Dict[String, Any]
    ) raises -> None:
        var request = AsyncTradingRequest(
            type=1,
            data=CancelOrderRequestData(symbol=symbol, order_id=id),
            exchange=UnsafePointer.address_of(self),
        )
        _ = async_trading_channel_ptr()[].send(request)

    fn on_order(self, order: Order) -> None:
        if self._on_order != UnsafePointer[OnOrderC]():
            self._on_order[](self._trading_context, order)

    fn keep_alive(self) -> None:
        pass


fn _request_callback(
    req_id: UInt64,
    type_: UInt32,
    source: UnsafePointer[c_void],
    res: HttpResponsePtr,
) -> None:
    logd("request_callback req_id: " + str(req_id))
    logd("request_callback status_code: " + str(http_response_status_code(res)))
    alias buf_size = 1024 * 1000
    var buf = stack_allocation[buf_size, Int8]()
    var body = http_response_body(res, buf, buf_size)
    logd("request_callback text: " + String(StringRef(buf, body)))
