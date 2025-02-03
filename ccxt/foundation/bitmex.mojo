from memory import UnsafePointer
from collections import Dict
from collections.optional import _NoneType
from monoio_connect import (
    Fixed,
    QueryStringBuilder,
    logd,
    logi,
    Method,
    Headers,
    compute_hmac_sha256_hex,
)
from ccxt.base.types import (
    TradingContext,
    Ticker,
    OrderBook,
    OrderbookEntry,
    Trade,
    Balance,
    Order,
    ExchangeId,
    Market,
    MarketInterface,
    Currency,
    CurrencyInterface,
    OnOrderC,
    order_decorator,
    Entry,
    ApiType,
    OrderType,
    OrderSide,
    Balances,
    Strings,
    IntOpt,
    Str,
    Any,
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
)
from ccxt.base.exchange import Exchange
from ccxt.base.exchangeable import Exchangeable
from ccxt.abstract.bitmex import ImplicitAPI
from monoio_connect import now_ms
from sonic import (
    JsonValue,
    JsonObject,
    JsonArray,
    JsonValueRefObjectView,
    JsonValueRefArrayView,
    JsonValueObjectView,
    JsonValueArrayView,
    JsonObjectViewable,
    c_void,
)
from monoio_connect import compute_sha512_hex, compute_hmac_sha512_hex
from monoio_connect import HttpClientOptions, HttpClient, HttpResponsePtr
from monoio_connect import (
    MonoioRuntimePtr,
    http_response_status_code,
    http_response_body,
)
from ._base import empty_on_order
from small_time.small_time import strptime
from toolbox import to_unix_timestamp, to_unix_timestamp_microseconds


struct BitMEX(Exchangeable):
    var _default_type: String
    var _client: UnsafePointer[HttpClient]
    var _host: String
    var _api: ImplicitAPI
    var _base: Exchange
    var _api_key: String
    var _api_secret: String
    var _testnet: Bool
    var _on_order: OnOrderC
    var _trading_context: TradingContext
    var _verbose: Bool

    fn __init__(
        out self,
        config: Dict[String, Any],
        trading_context: TradingContext,
        rt: MonoioRuntimePtr = MonoioRuntimePtr(),
    ):
        self._default_type = String("future")
        self._client = UnsafePointer[HttpClient].alloc(1)
        self._api = ImplicitAPI()
        self._base = Exchange(config)
        self._api_key = str(config.get("api_key", String()))
        self._api_secret = str(config.get("api_secret", String()))
        self._testnet = config.get("testnet", False).bool()
        self._verbose = config.get("verbose", False).bool()
        self._on_order = order_decorator(empty_on_order)
        self._trading_context = trading_context
        var base_url = "https://www.bitmex.com" if not self._testnet else "https://testnet.bitmex.com"
        self._host = String(base_url).replace("https://", "")
        var options = HttpClientOptions(base_url)
        __get_address_as_uninit_lvalue(self._client.address) = HttpClient(
            options, rt, self._verbose
        )

    fn __del__(owned self):
        self._client.destroy_pointee()
        self._client.free()

    fn __moveinit__(out self, owned other: Self):
        self._default_type = other._default_type
        self._host = other._host
        self._client = other._client
        other._client = UnsafePointer[HttpClient]()
        self._testnet = other._testnet
        self._verbose = other._verbose
        self._api = other._api^
        self._base = other._base^
        self._api_key = other._api_key
        self._api_secret = other._api_secret
        self._on_order = other._on_order
        self._trading_context = other._trading_context

    fn set_on_order(mut self, owned on_order: OnOrderC) -> None:
        self._on_order = on_order

    fn id(self) -> ExchangeId:
        return ExchangeId.bitmex

    @always_inline
    fn _request[
        max_body_size: Int = 1024 * 1000
    ](
        self,
        entry: Entry,
        params: Dict[String, Any],
        query: String = "",
        payload: String = "",
    ) raises -> String:
        # logd("entry: " + entry.path)
        return self._request[max_body_size](
            entry.method, entry.path, params, query, payload, entry.api
        )

    @always_inline
    fn _request[
        max_body_size: Int = 1024 * 1000
    ](
        self,
        method: Method,
        path: String,
        params: Dict[String, Any],
        query: String = "",
        payload: String = "",
        api: ApiType = ApiType.Public,
    ) raises -> String:
        var entry_path = path
        for key in params:
            # logi("key: " + key[] + ", value: " + str(params[key[]]))
            var value = params[key[]]
            entry_path = entry_path.replace("{" + key[] + "}", str(value))
        var path_ = "/api/v1/" + entry_path
        var full_path = path_
        if query != "":
            full_path += "?" + query
        var headers = Headers()

        headers["host"] = self._host
        headers["user-agent"] = "monoio-http"
        headers["accept-encoding"] = "gzip, deflate"
        headers["accept"] = "application/json"

        if api == ApiType.Private:
            var expires = int(now_ms() / 1000) + 100
            var method_str = String("")
            if method == Method.METHOD_GET:
                method_str = "GET"
            elif method == Method.METHOD_POST:
                method_str = "POST"
                # headers["content-type"] = "application/x-www-form-urlencoded"
                # headers["X-Requested-With"] = "XMLHttpRequest"
                # headers["Content-type"] = "application/json"
            elif method == Method.METHOD_PUT:
                method_str = "PUT"
                # headers["content-type"] = "application/x-www-form-urlencoded"
                # headers["X-Requested-With"] = "XMLHttpRequest"
                # headers["Content-type"] = "application/json"
            elif method == Method.METHOD_DELETE:
                method_str = "DELETE"
                # headers["content-type"] = "application/x-www-form-urlencoded"
                # headers["X-Requested-With"] = "XMLHttpRequest"
                # headers["Content-type"] = "application/json"
            else:
                raise Error("Invalid method: " + str(method))

            headers["api-expires"] = str(expires)
            headers["api-key"] = self._api_key
            headers["api-signature"] = self._sign_payload(
                method_str, path_, expires, query
            )
        # logd("payload: " + payload)

        var response = self._client[].request[max_body_size](
            full_path, method, headers, payload
        )
        # {"error":{"message":"Full authentication is required to access this resource","name":"HTTPError"}}
        if response.status_code == 0:
            raise Error("HTTP status code: " + str(response.status_code))
        if response.status_code >= 200 and response.status_code < 300:
            return response.text
        elif response.status_code >= 400 and response.status_code < 500:
            var doc = JsonObject(response.text)
            var error = doc.get_object_mut("error")
            var message = error.get_str("message")
            _ = doc^
            raise Error(
                String.format(
                    "HTTP status code: {}, message: {}",
                    response.status_code,
                    message,
                )
            )
        return response.text

    fn _sign_payload(
        self,
        method: String,
        path: String,
        expires: Int,
        payload: String,
    ) raises -> String:
        # message = verb + url + str(nonce) + data
        var message = String.write(
            method,
            path,
            "?" + payload if len(payload) > 0 else "",
            str(expires),
        )
        if self._verbose:
            logd("sign message: " + message)
        return compute_hmac_sha256_hex(message, self._api_secret)

    fn load_markets(self, mut params: Dict[String, Any]) raises -> List[Market]:
        raise Error("NotImplemented")

    fn fetch_markets(
        self, mut params: Dict[String, Any]
    ) raises -> List[Market]:
        var text = self._request(
            self._api.public_get_instrument_active, params, "", ""
        )
        var doc = JsonObject(text)
        var arr = JsonValueArrayView(doc)
        var n = arr.len()
        var result = List[Market](capacity=n)
        for i in range(0, n):
            var obj = arr.get(i)
            var obj_view = JsonValueRefObjectView(obj)
            """
            var info: Dict[String, Any]
            var id: Str
            var symbol: Str
            var base: Str
            var quote: Str
            var baseId: Str
            var quoteId: Str
            var active: Bool
            var type: Str
            var subType: Str
            var spot: Bool
            var margin: Bool
            var marginModes: MarketMarginModes
            var swap: Bool
            var future: Bool
            var option: Bool
            var contract: Bool
            var settle: Str
            var settleId: Str
            var contractSize: Fixed
            var linear: Bool
            var inverse: Bool
            var expiry: Num
            var expiryDatetime: Str
            var strike: Num
            var optionType: Str
            var taker: Fixed
            var maker: Fixed
            var percentage: Bool
            var tierBased: Bool
            var feeSide: Str
            var precision: Any
            var limits: MarketLimits
            var created: Int
            """

            """
            {
                "symbol": "XRPUSDT",
                "rootSymbol": "XRP",
                "state": "Open",
                "typ": "FFWCSX",
                "listing": "2021-10-04T04:00:00.000Z",
                "front": "2021-10-04T04:00:00.000Z",
                "positionCurrency": "XRP",
                "underlying": "XRP",
                "quoteCurrency": "USDT",
                "underlyingSymbol": "XRPT=",
                "reference": "BMEX",
                "referenceSymbol": ".BXRPT",
                "maxOrderQty": 1000000000,
                "maxPrice": 10000,
                "lotSize": 1000,
                "tickSize": 0.0001,
                "multiplier": 10000,
                "settlCurrency": "USDt",
                "underlyingToPositionMultiplier": 100,
                "quoteToSettleMultiplier": 1000000,
                "isQuanto": false,
                "isInverse": false,
                "initMargin": 0.01,
                "maintMargin": 0.005,
                "riskLimit": 1000000000000,
                "riskStep": 1000000000000,
                "taxed": true,
                "deleverage": true,
                "makerFee": 0.0005,
                "takerFee": 0.0005,
                "settlementFee": 0,
                "fundingBaseSymbol": ".XRPBON8H",
                "fundingQuoteSymbol": ".USDTBON8H",
                "fundingPremiumSymbol": ".XRPUSDTPI8H",
                "fundingTimestamp": "2025-01-30T12:00:00.000Z",
                "fundingInterval": "2000-01-01T08:00:00.000Z",
                "fundingRate": 0.0001,
                "indicativeFundingRate": 0.0001,
                "prevClosePrice": 3.08648,
                "limitDownPrice": null,
                "limitUpPrice": null,
                "prevTotalVolume": 7053147000,
                "totalVolume": 7053147000,
                "volume": 0,
                "volume24h": 79000,
                "prevTotalTurnover": 71455821746000,
                "totalTurnover": 71455821746000,
                "turnover": 0,
                "turnover24h": 2417707000,
                "homeNotional24h": 790,
                "foreignNotional24h": 2417.7070000000003,
                "prevPrice24h": 3.0963,
                "vwap": 3.0603887,
                "highPrice": 3.117,
                "lowPrice": 3.007,
                "lastPrice": 3.1038,
                "lastPriceProtected": 3.1038,
                "lastTickDirection": "PlusTick",
                "lastChangePcnt": -0.0012,
                "bidPrice": 3.1058,
                "midPrice": 3.1082,
                "askPrice": 3.1106,
                "impactBidPrice": 3.1039075,
                "impactMidPrice": 3.10815,
                "impactAskPrice": 3.1124862,
                "hasLiquidity": true,
                "openInterest": 121879000,
                "openValue": 3788121199000,
                "fairMethod": "FundingRate",
                "fairBasisRate": 0.1095,
                "fairBasis": 0.0001,
                "fairPrice": 3.1081,
                "markMethod": "FairPrice",
                "markPrice": 3.1081,
                "indicativeSettlePrice": 3.108,
                "instantPnl": true,
                "timestamp": "2025-01-30T09:22:06.307Z",
                "minTick": 0.00001,
                "fundingBaseRate": 0.0003,
                "fundingQuoteRate": 0.0006,
                "capped": false
            }
            """
            var market = MarketInterface()
            var symbol = obj_view.get_str("symbol")
            var rootSymbol = obj_view.get_str("rootSymbol")
            var state = obj_view.get_str("state")
            var typ = obj_view.get_str("typ")
            var listing = obj_view.get_str("listing")
            var front = obj_view.get_str("front")
            var positionCurrency = obj_view.get_str("positionCurrency")
            var underlying = obj_view.get_str("underlying")
            var quoteCurrency = obj_view.get_str("quoteCurrency")
            var lotSize = obj_view.get_f64("lotSize")
            var tickSize = obj_view.get_f64("tickSize")
            var multiplier = obj_view.get_f64("multiplier")
            var settleCurrency = obj_view.get_str("settlCurrency")
            var underlyingToPositionMultiplier = obj_view.get_f64(
                "underlyingToPositionMultiplier"
            )
            var quoteToSettleMultiplier = obj_view.get_f64(
                "quoteToSettleMultiplier"
            )
            market.symbol = symbol
            market.base = rootSymbol
            market.quote = quoteCurrency
            market.baseId = positionCurrency
            market.quoteId = quoteCurrency
            market.active = state == "Open"
            market.type = typ
            market.subType = typ
            market.spot = False
            market.margin = False
            # market.marginModes = MarketMarginModes(False, False)
            market.swap = True
            market.future = False
            market.option = False
            market.contract = False
            market.settle = settleCurrency
            market.settleId = settleCurrency
            market.contractSize = Fixed(lotSize * multiplier)
            market.linear = False
            market.inverse = False
            market.expiry = 0
            market.expiryDatetime = None
            market.strike = 0
            market.optionType = None
            market.taker = Fixed(0)
            market.maker = Fixed(0)
            market.percentage = False
            market.tierBased = False
            # market.feeSide = "quote"
            # market.precision = None
            # market.limits = MarketLimits()
            market.created = 0
            result.append(market)
        _ = arr^
        _ = doc^
        return result

    fn fetch_currencies(
        self, mut params: Dict[String, Any]
    ) raises -> List[Currency]:
        var text = self._request(
            self._api.public_get_wallet_assets, params, "", ""
        )
        var doc = JsonObject(text)
        var result = List[Currency]()
        var arr = JsonValueArrayView(doc)
        var n = arr.len()
        for i in range(0, n):
            var obj = arr.get(i)
            """
            {
                "asset": "MATIC",
                "currency": "MATIc",
                "majorCurrency": "MATIC",
                "name": "Matic",
                "currencyType": "Crypto",
                "scale": 8,
                "enabled": true,
                "isMarginCurrency": false,
                "minDepositAmount": 700000000,
                "minWithdrawalAmount": 700000000,
                "maxWithdrawalAmount": 7000000000000000,
                "memoRequired": false,
                "networks": [
                    {
                        "asset": "ropsten",
                        "tokenAddress": "0xDA1628b5Ad369448c79C212d4350e6125D920863",
                        "depositEnabled": false,
                        "withdrawalEnabled": false,
                        "withdrawalFee": 1600000000,
                        "minFee": 1600000000,
                        "maxFee": 1600000000
                    }
                ]
            }
            """
            var obj_view = JsonValueRefObjectView(obj)
            var currency = CurrencyInterface()
            currency.id = obj_view.get_str("asset")
            currency.code = obj_view.get_str("currency")
            currency.numericId = 0
            currency.precision = Fixed(obj_view.get_f64("scale"))
            currency.type = obj_view.get_str("currencyType")
            currency.margin = obj_view.get_bool("isMarginCurrency")
            currency.name = obj_view.get_str("name")
            currency.active = obj_view.get_bool("enabled")
            currency.deposit = False
            currency.withdraw = False
            result.append(currency)
        _ = arr^
        _ = doc^
        return result

    fn fetch_ticker(self, symbol: String) raises -> Ticker:
        var params = Dict[String, Any]()
        var query = "symbol=" + symbol if len(symbol) > 0 else ""
        var text = self._request(
            self._api.public_get_instrument, params, query, ""
        )
        var doc = JsonObject(text)
        var arr = JsonValueArrayView(doc)
        var n = arr.len()
        if n == 0:
            raise Error("No ticker found")
        if n > 1:
            raise Error("Multiple tickers found")
        var obj = arr.get(0)
        var obj_view = JsonValueRefObjectView(obj)
        return self.parse_ticker(obj_view)

    fn parse_ticker(self, obj_view: JsonValueRefObjectView) raises -> Ticker:
        """
        [{"symbol":"XRPUSDT","rootSymbol":"XRP","state":"Open","typ":"FFWCSX","listing":"2021-10-04T04:00:00.000Z","front":"2021-10-04T04:00:00.000Z","positionCurrency":"XRP","underlying":"XRP","quoteCurrency":"USDT","underlyingSymbol":"XRPT=","reference":"BMEX","referenceSymbol":".BXRPT","maxOrderQty":1000000000,"maxPrice":10000,"lotSize":1000,"tickSize":0.0001,"multiplier":10000,"settlCurrency":"USDt","underlyingToPositionMultiplier":100,"quoteToSettleMultiplier":1000000,"isQuanto":false,"isInverse":false,"initMargin":0.01,"maintMargin":0.005,"riskLimit":1000000000000,"riskStep":1000000000000,"taxed":true,"deleverage":true,"makerFee":0.0005,"takerFee":0.0005,"settlementFee":0,"fundingBaseSymbol":".XRPBON8H","fundingQuoteSymbol":".USDTBON8H","fundingPremiumSymbol":".XRPUSDTPI8H","fundingTimestamp":"2025-01-30T20:00:00.000Z","fundingInterval":"2000-01-01T08:00:00.000Z","fundingRate":0.0001,"indicativeFundingRate":0.0001,"prevClosePrice":3.10212,"limitDownPrice":null,"limitUpPrice":null,"prevTotalVolume":7053172000,"totalVolume":7055700000,"volume":2528000,"volume24h":2619000,"prevTotalTurnover":71456595929000,"totalTurnover":71536338552000,"turnover":79742623000,"turnover24h":82533771000,"homeNotional24h":26190,"foreignNotional24h":82533.77100000001,"prevPrice24h":3.0579,"vwap":3.1513468,"highPrice":3.1627,"lowPrice":3.007,"lastPrice":3.1627,"lastPriceProtected":3.1584232,"lastTickDirection":"PlusTick","lastChangePcnt":0.0343,"bidPrice":3.1351,"midPrice":3.1375,"askPrice":3.1399,"impactBidPrice":3.1332163,"impactMidPrice":3.13745,"impactAskPrice":3.1417774,"hasLiquidity":true,"openInterest":119350000,"openValue":3741001880000,"fairMethod":"FundingRate","fairBasisRate":0.1095,"fairBasis":0.00018,"fairPrice":3.13448,"markMethod":"FairPrice","markPrice":3.13448,"indicativeSettlePrice":3.1343,"instantPnl":true,"timestamp":"2025-01-30T15:17:00.773Z","minTick":0.00001,"fundingBaseRate":0.0003,"fundingQuoteRate":0.0006,"capped":false}]
        """
        var timestamp = obj_view.get_str("timestamp")
        var datetime = strptime(timestamp, "%Y-%m-%dT%H:%M:%S.%fZ")
        var timestamp_microseconds = to_unix_timestamp_microseconds(datetime)
        # var timestamp_seconds = to_unix_timestamp(datetime)
        var ticker = Ticker()
        ticker.info = Dict[String, Any]()
        ticker.symbol = obj_view.get_str("symbol")
        # "timestamp":"2025-01-30T15:17:00.773Z"
        ticker.datetime = timestamp
        ticker.timestamp = int(timestamp_microseconds / 1000)
        ticker.high = Fixed(obj_view.get_f64("highPrice"))
        ticker.low = Fixed(obj_view.get_f64("lowPrice"))
        ticker.bid = Fixed(obj_view.get_f64("bidPrice"))
        ticker.bidVolume = Fixed(obj_view.get_f64("bidVolume"))
        ticker.ask = Fixed(obj_view.get_f64("askPrice"))
        ticker.askVolume = Fixed(obj_view.get_f64("askVolume"))
        ticker.vwap = Fixed(obj_view.get_f64("vwap"))
        ticker.open = Fixed(obj_view.get_f64("open"))
        ticker.close = Fixed(obj_view.get_f64("close"))
        ticker.last = Fixed(obj_view.get_f64("lastPrice"))
        ticker.previousClose = Fixed(obj_view.get_f64("prevClosePrice"))
        ticker.change = Fixed(obj_view.get_f64("lastChangePcnt"))
        ticker.percentage = Fixed(obj_view.get_f64("lastChangePcnt"))
        ticker.average = Fixed(obj_view.get_f64("average"))
        ticker.quoteVolume = Fixed(obj_view.get_f64("quoteVolume"))
        ticker.baseVolume = Fixed(obj_view.get_f64("baseVolume"))
        ticker.markPrice = Fixed(obj_view.get_f64("markPrice"))
        ticker.indexPrice = Fixed(obj_view.get_f64("indexPrice"))
        return ticker

    fn fetch_tickers(
        self, symbols: Strings, mut params: Dict[String, Any]
    ) raises -> List[Ticker]:
        var text = self._request[max_body_size = 1024 * 1000 * 100](
            self._api.public_get_instrument_activeandindices, params, "", ""
        )
        var doc = JsonObject(text)
        var arr = JsonValueArrayView(doc)
        var n = arr.len()
        if n == 0:
            raise Error("No ticker found")

        var result = List[Ticker](capacity=n)
        for i in range(0, n):
            var obj = arr.get(i)
            var obj_view = JsonValueRefObjectView(obj)
            var ticker = self.parse_ticker(obj_view)
            result.append(ticker)
        _ = arr^
        _ = doc^
        return result

    fn fetch_order_book(
        self,
        symbol: String,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> OrderBook:
        var query = "symbol=" + symbol if len(symbol) > 0 else ""
        var text = self._request(
            self._api.public_get_orderbook_l2, params, query, ""
        )
        # [{"symbol":"XRPUSDT","id":2220863936,"side":"Sell","size":25000000,"price":3.5000,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"},{"symbol":"XRPUSDT","id":2247908545,"side":"Sell","size":100000,"price":3.4070,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"},{"symbol":"XRPUSDT","id":2235039633,"side":"Sell","size":50000,"price":3.3764,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"},{"symbol":"XRPUSDT","id":2269427221,"side":"Sell","size":4919000,"price":2.2665,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.057Z"},{"symbol":"XRPUSDT","id":2269427217,"side":"Sell","size":4182000,"price":2.2639,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.056Z"},{"symbol":"XRPUSDT","id":2269427213,"side":"Sell","size":3198000,"price":2.2608,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.056Z"},{"symbol":"XRPUSDT","id":2269427209,"side":"Sell","size":2460000,"price":2.2582,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.056Z"},{"symbol":"XRPUSDT","id":2269427205,"side":"Sell","size":1968000,"price":2.2551,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.054Z"},{"symbol":"XRPUSDT","id":2269427201,"side":"Sell","size":1722000,"price":2.2525,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.054Z"},{"symbol":"XRPUSDT","id":2269427197,"side":"Sell","size":1230000,"price":2.2494,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.053Z"},{"symbol":"XRPUSDT","id":2269427193,"side":"Sell","size":984000,"price":2.2467,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.053Z"},{"symbol":"XRPUSDT","id":2269427189,"side":"Sell","size":738000,"price":2.2437,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.052Z"},{"symbol":"XRPUSDT","id":2269427185,"side":"Sell","size":492000,"price":2.2410,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.052Z"},{"symbol":"XRPUSDT","id":2269427181,"side":"Sell","size":246000,"price":2.2380,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.051Z"},{"symbol":"XRPUSDT","id":2269427179,"side":"Buy","size":246000,"price":2.2346,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.051Z"},{"symbol":"XRPUSDT","id":2269427183,"side":"Buy","size":492000,"price":2.2316,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.052Z"},{"symbol":"XRPUSDT","id":2269427187,"side":"Buy","size":738000,"price":2.2289,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.052Z"},{"symbol":"XRPUSDT","id":2269427191,"side":"Buy","size":984000,"price":2.2259,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.053Z"},{"symbol":"XRPUSDT","id":2269427195,"side":"Buy","size":1230000,"price":2.2232,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.053Z"},{"symbol":"XRPUSDT","id":2269427199,"side":"Buy","size":1722000,"price":2.2201,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.053Z"},{"symbol":"XRPUSDT","id":2269427203,"side":"Buy","size":1968000,"price":2.2175,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.054Z"},{"symbol":"XRPUSDT","id":2269427207,"side":"Buy","size":2460000,"price":2.2144,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.054Z"},{"symbol":"XRPUSDT","id":2269427211,"side":"Buy","size":3198000,"price":2.2118,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.056Z"},{"symbol":"XRPUSDT","id":2269427215,"side":"Buy","size":4182000,"price":2.2087,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.056Z"},{"symbol":"XRPUSDT","id":2269427219,"side":"Buy","size":4919000,"price":2.2061,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T03:49:51.057Z"},{"symbol":"XRPUSDT","id":1721362433,"side":"Buy","size":3000,"price":0.4444,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"},{"symbol":"XRPUSDT","id":1411884448,"side":"Buy","size":99999000,"price":0.2001,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"},{"symbol":"XRPUSDT","id":574,"side":"Buy","size":9709000,"price":0.2000,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"},{"symbol":"XRPUSDT","id":708,"side":"Buy","size":4940000,"price":0.1084,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"}]
        var doc = JsonObject(text)
        var arr = JsonValueArrayView(doc)
        var n = arr.len()
        if n == 0:
            raise Error("No order book found")
        var result = OrderBook()
        result.symbol = symbol
        for i in range(0, n):
            # {"symbol":"XRPUSDT","id":2220863936,"side":"Sell","size":25000000,"price":3.5000,"timestamp":"2025-02-03T03:49:51.057Z","transactTime":"2025-02-03T02:00:00.001Z"}
            var obj = arr.get(i)
            var obj_view = JsonValueRefObjectView(obj)
            if i == 0:
                var timestamp = obj_view.get_str("timestamp")
                var datetime = strptime(timestamp, "%Y-%m-%dT%H:%M:%S.%fZ")
                var timestamp_microseconds = to_unix_timestamp_microseconds(
                    datetime
                )
                result.timestamp = int(timestamp_microseconds / 1000)
                result.datetime = timestamp
            var order_book_entry = OrderbookEntry()
            var side = obj_view.get_str("side")
            var price = obj_view.get_f64("price")
            var amount = obj_view.get_f64("size")
            order_book_entry.price = Fixed(price)
            order_book_entry.amount = amount
            if side == "Buy":
                result.bids.append(order_book_entry)
            else:
                result.asks.append(order_book_entry)
        _ = arr^
        _ = doc^
        return result

    fn fetch_trades(
        self,
        symbol: String,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        var builder = QueryStringBuilder()
        builder["symbol"] = symbol
        if limit:
            builder["limit"] = str(limit.value())
        if since:
            builder["since"] = str(since.value())
        var query = builder.to_string()
        var text = self._request(self._api.public_get_trade, params, "", query)
        # [{"timestamp":"2023-09-08T16:41:00.000Z","symbol":".BUSDP","side":"Buy","size":0,"price":0.99763,"tickDirection":"ZeroMinusTick","trdType":"Referential"}]
        var doc = JsonObject(text)
        var arr = JsonValueArrayView(doc)
        var n = arr.len()
        var result = List[Trade](capacity=n)
        for i in range(0, n):
            var obj = arr.get(i)
            var obj_view = JsonValueRefObjectView(obj)
            var trade = Trade()
            # trade.id = obj_view.get_str("id")
            trade.symbol = obj_view.get_str("symbol")
            var timestamp = obj_view.get_str("timestamp")
            var datetime = strptime(timestamp, "%Y-%m-%dT%H:%M:%S.%fZ")
            var timestamp_microseconds = to_unix_timestamp_microseconds(
                datetime
            )
            trade.timestamp = int(timestamp_microseconds / 1000)
            trade.datetime = timestamp
            trade.price = Fixed(obj_view.get_f64("price"))
            trade.amount = obj_view.get_f64("size")
            trade.side = obj_view.get_str("side")
            result.append(trade)
        _ = arr^
        _ = doc^
        return result

    fn fetch_balance(self, mut params: Dict[String, Any]) raises -> Balances:
        var text = self._request(
            self._api.private_get_user_margin, params, "", ""
        )
        # {"error":{"message":"Full authentication is required to access this resource","name":"HTTPError"}}
        # {"account":215305,"currency":"XBt","riskLimit":1000000000000,"amount":202,"grossComm":0,"grossOpenCost":0,"grossOpenPremium":0,"grossMarkValue":0,"riskValue":0,"initMargin":0,"maintMargin":0,"targetExcessMargin":202,"realisedPnl":0,"unrealisedPnl":0,"walletBalance":202,"marginBalance":202,"marginLeverage":0,"marginUsedPcnt":0,"excessMargin":202,"availableMargin":202,"withdrawableMargin":202,"timestamp":"2024-09-27T05:43:39.607Z","foreignMarginBalance":0,"foreignRequirement":0}
        var doc = JsonObject(text)
        var currency = doc.get_str("currency")
        var amount = doc.get_f64("amount")
        var balance = Balance()
        balance.free = Fixed(amount)
        balance.used = Fixed.zero
        balance.total = Fixed(amount)
        _ = doc^
        var balances = Balances()
        balances.data[currency] = balance
        balances.datetime = str(now_ms())
        balances.timestamp = now_ms()
        return balances

    fn create_order(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> Order:
        var builder = QueryStringBuilder()
        builder["symbol"] = symbol
        builder["side"] = "Buy" if side == OrderSide.Buy else "Sell"
        builder["orderQty"] = str(amount)
        builder["price"] = str(price)
        builder["ordType"] = "Limit" if type == OrderType.Limit else "Market"
        var query = builder.to_string()
        # var post_doc = JsonObject()
        # post_doc.insert_str("symbol", symbol)
        # post_doc.insert_str("side", "Buy" if side == OrderSide.Buy else "Sell")
        # post_doc.insert_str("orderQty", str(amount))
        # post_doc.insert_str("price", str(price))
        # post_doc.insert_str(
        #     "ordType", "Limit" if type == OrderType.Limit else "Market"
        # )
        # var body_str = post_doc.to_string()

        var text = self._request(
            self._api.private_post_order, params, query, ""
        )
        # {"error":{"message":"Full authentication is required to access this resource","name":"HTTPError"}}
        #
        # var doc = JsonObject(text)
        # var order_id = doc.get_str("orderID")
        var order = Order()
        # order.id = order_id
        # _ = doc^
        return order

    fn cancel_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        raise Error("NotImplemented")

    @staticmethod
    fn parse_order(doc: JsonObject) raises -> Order:
        raise Error("NotImplemented")

    fn fetch_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        raise Error("NotImplemented")

    fn fetch_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        raise Error("NotImplemented")

    fn fetch_open_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        raise Error("NotImplemented")

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
        pass

    fn cancel_order_async(
        self, id: String, symbol: String, mut params: Dict[String, Any]
    ) raises -> None:
        pass

    fn on_order(self, order: Order) -> None:
        self._on_order(self._trading_context, order)

    fn keep_alive(self) -> None:
        pass
