from collections import Dict
from os import getenv
from testing import assert_equal, assert_true
from memory import UnsafePointer, stack_allocation
from mojoenv import load_mojo_env
from monoio_connect import *
from ccxt.base.types import Any, OrderType, OrderSide, Num, Order, Ticker
from ccxt.base.pro_exchangeable import TradingContext, ExchangeId
from ccxt.foundation.bybit import Bybit
from ccxt.foundation.binance import Binance
from ccxt.foundation.gate import Gate
from ccxt.pro.gate import Gate as GatePro


fn test_http_get() raises -> None:
    var base_url = String("https://httpbin.org")
    var options = HttpClientOptions(base_url=base_url)
    var http = HttpClient(options)
    var headers = Headers()
    headers["Host"] = "captive.apple.com"
    headers["Accept"] = "*/*"
    headers["User-Agent"] = "monoio-http"
    headers["Accept-Encoding"] = "gzip, deflate"
    var path = String("/get")
    var resp = http.request(path, Method.METHOD_GET, headers, "")
    print(resp.status_code)
    print(resp.text)


fn test_binance_fetch_balance() raises -> None:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BINANCE_API_KEY"]
    var api_secret = env_vars["BINANCE_API_SECRET"]
    var testnet = parse_bool(env_vars["BINANCE_TESTNET"])

    var base_url = String("https://testnet.binancefuture.com")
    # var base_url = String("https://fx-api-testnet.gateio.ws")
    var options = HttpClientOptions(base_url=base_url)
    var http = HttpClient(options)
    var headers = Headers()
    headers["host"] = "testnet.binancefuture.com"
    # headers["host"] = "fx-api-testnet.gateio.ws"
    # headers["accept"] = "*/*"
    headers["user-agent"] = "monoio-http"
    headers["accept-encoding"] = "gzip, deflate"
    var path = String("/fapi/v3/account")
    var data = ""
    var ts_str = "recvWindow=5000&timestamp=" + str(now_ms())
    var payload = data + "&" + ts_str if data != "" else ts_str
    var signature = compute_hmac_sha256_hex(payload, api_secret)
    headers["X-MBX-APIKEY"] = api_key
    var p = payload + "&signature=" + signature
    path += "?" + p
    var resp = http.request(path, Method.METHOD_GET, headers, "")
    print(resp.status_code)
    print(resp.text)


fn on_order(trading_context: TradingContext, order: Order) -> None:
    logd("on_order start")
    # logd("trading_context: " + str(trading_context))
    # logd("order: " + str(order))
    logd("exchange_id: " + str(trading_context.exchange_id))
    logd("account_id: " + trading_context.account_id)
    logd("trader_id: " + trading_context.trader_id)
    logd("=============")
    logd("id: " + order.id)
    logd("symbol: " + order.symbol)
    logd("type: " + order.type)
    logd("side: " + str(order.side))
    logd("amount: " + str(order.amount))
    logd("price: " + str(order.price))
    logd("on_order end")


fn test_binance() raises -> None:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BINANCE_API_KEY"]
    var api_secret = env_vars["BINANCE_API_SECRET"]
    var testnet = parse_bool(env_vars["BINANCE_TESTNET"])

    var rt = create_monoio_runtime()
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet

    var trading_context = TradingContext(
        exchange_id=ExchangeId.binance, account_id="1", trader_id="1"
    )
    var binance = Binance(config, trading_context, rt)
    var params = Dict[String, Any]()

    binance.set_on_order(on_order)

    # var markets = binance.fetch_markets(params)
    # for market in markets:
    #     logt(str(market[].value()))

    # var currencies = binance.fetch_currencies(params)
    # for currency in currencies:
    #     print(str(currency[].value()))

    # var ticker = binance.fetch_ticker("BTCUSDT")
    # logd(str(ticker))

    # var symbols = List[String](capacity=2)
    # symbols.append("BTCUSDT")
    # symbols.append("ETHUSDT")
    # var tickers = binance.fetch_tickers(symbols, params)
    # for ticker in tickers:
    #     logd(str(ticker[]))

    # var order_book = binance.fetch_order_book("BTCUSDT", 10, params)
    # logd(str(order_book))

    # logd("len(asks)=" + str(len(order_book.asks)))
    # logd("len(bids)=" + str(len(order_book.bids)))
    # logd("ask: " + str(order_book.asks[0]))
    # logd("bid: " + str(order_book.bids[0]))

    # var trades = binance.fetch_trades("BTCUSDT", None, None, params)
    # for trade in trades:
    #     logd(str(trade))

    var balance = binance.fetch_balance(params)
    logd(str(balance))

    # monoio_sleep_ms(rt, 10)

    # logd("create_order")
    # try:
    #     var order = binance.create_order(
    #         "BTC_USDT",
    #         OrderType.Limit,
    #         OrderSide.Buy,
    #         Fixed(1.0),
    #         Fixed(93000),
    #         params,
    #     )
    #     logd(str(order))
    # except e:
    #     logd("create_order error: " + str(e))
    # logd("create_order end")

    # try:
    #     _ = binance.create_order_async(
    #         "BTC_USDT",
    #         OrderType.Limit,
    #         OrderSide.Buy,
    #         Fixed(1.0),
    #         Fixed(93000),
    #         params,
    #     )
    # except e:
    #     logd("create_order_async error: " + str(e))

    # logd("cancel_order")

    # var cancel_order = binance.cancel_order(
    #     String("58828270140601928"), String("BTC_USDT"), params
    # )
    # logd(str(cancel_order))
    # logd("cancel_order end")

    logd("sleep")

    sleep_ms(rt, 10 * 60 * 1000)

    _ = binance^


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + str(trading_context) + " " + str(ticker))


# ws
fn test_ws(api_key: String, api_secret: String, testnet: Bool) raises -> None:
    var rt = create_monoio_runtime()
    var config_pro = Dict[String, Any]()

    config_pro["api_key"] = api_key
    config_pro["api_secret"] = api_secret
    config_pro["testnet"] = testnet
    config_pro["settle"] = "usdt"

    var trading_context = TradingContext(
        exchange_id=ExchangeId.gateio, account_id="1", trader_id="1"
    )
    var gate_pro = GatePro(config_pro, trading_context)
    gate_pro.set_on_ticker(on_ticker)
    gate_pro.set_on_order(on_order)

    # Subscribe to order book depth data
    # var params0 = Dict[String, Any]()
    # params0["interval"] = "100ms"  # Update interval is 100ms
    # gate_pro.subscribe_order_book("BTC_USDT", params0)  # Subscribe to BTC/USDT order book

    # Subscribe to real-time ticker data
    var params1 = Dict[String, Any]()
    gate_pro.subscribe_ticker(
        "BTC_USDT", params1
    )  # Subscribe to BTC/USDT real-time ticker

    # Subscribe to order data
    # var params2 = Dict[String, Any]()
    # gate_pro.subscribe_order("BTC_USDT", params2)  # Subscribe to BTC/USDT order

    gate_pro.connect(rt)

    time.sleep(1000000.0)

    _ = gate_pro^


fn main() raises:
    var logger = init_logger(LogLevel.Debug, "", "")

    # test_monoiohttpclient()
    # test_http_get()
    # test_binance_fetch_balance()
    test_binance()
    # test_ws(api_key, api_secret, testnet)

    time.sleep(1000000.0)

    destroy_logger(logger)
