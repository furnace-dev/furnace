from memory import UnsafePointer
from collections import Dict
from collections.optional import _NoneType
from monoio_connect import logd, logi, Method
from monoio_connect.httpclient import Headers
from monoio_connect.fixed import Fixed
from ccxt.base.types import (
    TradingContext,
    Ticker,
    OrderBook,
    Trade,
    Balance,
    Order,
    ExchangeId,
    Market,
    Currency,
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
        self._api_key = String(config.get("api_key", String()))
        self._api_secret = String(config.get("api_secret", String()))
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
    fn _request(
        self,
        entry: Entry,
        params: Dict[String, Any],
        query: String = "",
        payload: String = "",
    ) raises -> String:
        # logd("entry: " + entry.path)
        return self._request(
            entry.method, entry.path, params, query, payload, entry.api
        )

    @always_inline
    fn _request(
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
            # logi("key: " + key[] + ", value: " + String(params[key[]]))
            var value = params[key[]]
            entry_path = entry_path.replace("{" + key[] + "}", String(value))
        var path_ = "/api/v1/" + entry_path
        var full_path = path_
        if query != "":
            full_path += "?" + query
        var headers = Headers()

        headers["host"] = self._host
        headers["user-agent"] = "monoio-http"
        headers["content-type"] = "application/json"
        headers["accept-encoding"] = "gzip, deflate"

        if api == ApiType.Private:
            # headers["SIGN"] = self._api_secret
            var ts = Int(now_ms() / 1000)
            var method_str = String("")
            if method == Method.METHOD_GET:
                method_str = "GET"
            elif method == Method.METHOD_POST:
                method_str = "POST"
            elif method == Method.METHOD_DELETE:
                method_str = "DELETE"
            else:
                raise Error("Invalid method: " + String(method))
            # var sign = self._sign_payload(method_str, path_, query, payload, ts)
            # headers["KEY"] = self._api_key
            # headers["SIGN"] = sign
            # headers["Timestamp"] = String(ts)
            # logd("sign: " + sign)
        # logd("payload: " + payload)

        var response = self._client[].request(
            full_path, method, headers, payload
        )
        if response.status_code == 0:
            raise Error("HTTP status code: " + String(response.status_code))
        if response.status_code >= 200 and response.status_code < 300:
            return response.text
        elif response.status_code >= 400 and response.status_code < 500:
            return response.text
        return response.text

    fn _sign_payload(
        self,
        method: String,
        path: String,
        param_string: String,
        data: String,
        ts: Int,
    ) raises -> String:
        # TODO: 需要实现
        var query_string = param_string

        var body_hash: String
        if len(data) > 0:
            body_hash = compute_sha512_hex(data)
        else:
            # 这里直接设置固定值，加快速度
            # body_hash = sha512_hex("")
            body_hash = "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"

        # s = f"{method}\n{path}\n{query_string}\n{body_hash}\n{ts}"
        # var s = method + "\n" + path + "\n" + query_string + "\n" + body_hash + "\n" + String(
        #     ts
        # )
        var s = String.write(
            method, "\n", path, "\n", query_string, "\n", body_hash, "\n", ts
        )
        # logd(s)
        return self._sign(s)

    @always_inline
    fn _sign(self, payload: String) raises -> String:
        # TODO: 需要实现
        return compute_hmac_sha512_hex(payload, self._api_secret)

    # 公共方法
    fn load_markets(self, mut params: Dict[String, Any]) raises -> List[Market]:
        raise Error("NotImplemented")

    fn fetch_markets(
        self, mut params: Dict[String, Any]
    ) raises -> List[Market]:
        raise Error("NotImplemented")

    fn fetch_currencies(
        self, mut params: Dict[String, Any]
    ) raises -> List[Currency]:
        raise Error("NotImplemented")

    fn fetch_ticker(self, symbol: String) raises -> Ticker:
        raise Error("NotImplemented")

    fn parse_ticker(self, obj_view: JsonValueRefObjectView) raises -> Ticker:
        raise Error("NotImplemented")

    fn fetch_tickers(
        self, symbols: Strings, mut params: Dict[String, Any]
    ) raises -> List[Ticker]:
        raise Error("NotImplemented")

    fn fetch_order_book(
        self,
        symbol: String,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> OrderBook:
        raise Error("NotImplemented")

    fn fetch_trades(
        self,
        symbol: String,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        raise Error("NotImplemented")

    # 私有方法
    fn fetch_balance(self, mut params: Dict[String, Any]) raises -> Balances:
        raise Error("NotImplemented")

    fn create_order(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> Order:
        raise Error("NotImplemented")

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
