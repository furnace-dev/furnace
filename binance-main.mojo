import time
from collections import Dict
from os import getenv
from testing import assert_equal, assert_true
from memory import UnsafePointer, stack_allocation
from mojoenv import load_mojo_env
from monoio_connect import (
    create_monoio_runtime,
    parse_bool,
    logd,
    logi,
    Fixed,
    init_logger,
    destroy_logger,
    LogLevel,
    HttpClientOptions,
    HttpClient,
    HttpResponse,
    HttpResponseCallback,
    Headers,
    Method,
    compute_hmac_sha256_hex,
    now_ms,
    sleep_ms,
    sleep,
)
from ccxt.base.types import (
    Any,
    OrderType,
    OrderSide,
    Num,
    Order,
    Ticker,
    ExchangeId,
    TradingContext,
)
from ccxt.foundation.bybit import Bybit
from ccxt.foundation.binance import Binance
from ccxt.pro.binance import Binance as BinancePro
from ccxt.foundation.gate import Gate
from ccxt.pro.gate import Gate as GatePro
from ccxt.foundation._async_trading_operations import (
    run_async_trading_thread,
)


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


# fn on_order(trading_context: TradingContext, order: Order) -> None:
#     logd("on_order start")
#     # logd("trading_context: " + str(trading_context))
#     # logd("order: " + str(order))
#     logd("exchange_id: " + str(trading_context.exchange_id))
#     logd("account_id: " + trading_context.account_id)
#     logd("trader_id: " + trading_context.trader_id)
#     logd("=============")
#     logd("id: " + order.id)
#     logd("symbol: " + order.symbol)
#     logd("type: " + order.type)
#     logd("side: " + str(order.side))
#     logd("amount: " + str(order.amount))
#     logd("price: " + str(order.price))
#     logd("on_order end")


fn test_binance() raises:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BINANCE_API_KEY"]
    var api_secret = env_vars["BINANCE_API_SECRET"]
    var testnet = parse_bool(env_vars["BINANCE_TESTNET"])

    var rt = create_monoio_runtime()
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    config["verbose"] = True

    var trading_context = TradingContext(
        exchange_id=ExchangeId.binance, account_id="1", trader_id="1"
    )
    var binance = Binance(config, trading_context, rt)
    var params = Dict[String, Any]()

    fn on_order(trading_context: TradingContext, order: Order) escaping -> None:
        logd("on_order start")
        logd("trading_context: " + str(trading_context))
        logd("order: " + str(order))
        logd("on_order end")

    binance.set_on_order(on_order)

    var symbol = "XRPUSDT"

    # var markets = binance.fetch_markets(params)
    # for market in markets:
    #     logt(str(market[].value()))

    # var currencies = binance.fetch_currencies(params)
    # for currency in currencies:
    #     print(str(currency[].value()))

    var ticker = binance.fetch_ticker(symbol)
    logd(str(ticker))

    # var symbols = List[String](capacity=2)
    # symbols.append("BTCUSDT")
    # symbols.append("ETHUSDT")
    # var tickers = binance.fetch_tickers(symbols, params)
    # for ticker in tickers:
    #     logd(str(ticker[]))

    # var order_book = binance.fetch_order_book(symbol, 10, params)
    # logd(str(order_book))

    # logd("len(asks)=" + str(len(order_book.asks)))
    # logd("len(bids)=" + str(len(order_book.bids)))
    # logd("ask: " + str(order_book.asks[0]))
    # logd("bid: " + str(order_book.bids[0]))

    # var trades = binance.fetch_trades(symbol, None, None, params)
    # for trade in trades:
    #     logd(str(trade))

    # var balance = binance.fetch_balance(params)
    # logd(str(balance))

    # sleep_ms(rt, 10)

    var mid_price = (
        (ticker.high + ticker.low) / Fixed(2) * Fixed(0.9)
    ).round_to_fractional(Fixed(0.0001))
    logd("mid_price: " + str(mid_price))

    var qty = (Fixed(10.0) / mid_price).round_to_fractional(Fixed(1))

    # var order = binance.create_order(
    #     symbol,
    #     OrderType.Limit,
    #     OrderSide.Buy,
    #     qty,
    #     mid_price,
    #     params,
    # )
    # logd(str(order))

    # var order_id = order.id
    var order_id = "260630021"

    # var order_result = binance.fetch_order(order_id, String(symbol), params)
    # logd(str(order_result))

    # var orders = binance.fetch_orders(String(symbol), None, None, params)
    # logd("len(orders)=" + str(len(orders)))
    # for order in orders:
    #     logd(str(order))

    var open_orders = binance.fetch_open_orders(
        String(symbol), None, None, params
    )
    logd("len(open_orders)=" + str(len(open_orders)))
    for order in open_orders:
        logd(str(order))

    # var cancel_order = binance.cancel_order(
    #     String("4077634200"), String(symbol), params
    # )
    # logd(str(cancel_order))

    logd("sleep")

    sleep_ms(rt, 10 * 60 * 1000)

    _ = binance^


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + str(trading_context) + " " + str(ticker))


# ws
fn test_ws() raises:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BINANCE_API_KEY"]
    var api_secret = env_vars["BINANCE_API_SECRET"]
    var testnet = parse_bool(env_vars["BINANCE_TESTNET"])

    var rt = create_monoio_runtime()
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    config["verbose"] = True
    config["is_private"] = True

    var trading_context = TradingContext(
        exchange_id=ExchangeId.binance, account_id="1", trader_id="1"
    )
    # var binance = Binance(config, trading_context, rt)
    # var listen_key = binance.generate_listen_key()
    # logd("listen_key: " + listen_key)

    var binance_pro = BinancePro(config, trading_context)
    binance_pro.set_on_ticker(on_ticker)
    binance_pro.set_on_order(on_order)

    # Subscribe to order book depth data
    # var params0 = Dict[String, Any]()
    # params0["interval"] = "100ms"  # Update interval is 100ms
    # binance_pro.subscribe_order_book("BTC_USDT", params0)  # Subscribe to BTC/USDT order book

    # Subscribe to real-time ticker data
    var params1 = Dict[String, Any]()
    binance_pro.subscribe_ticker(
        "xrpusdt", params1
    )

    # Subscribe to order data
    # var params2 = Dict[String, Any]()
    # binance_pro.subscribe_order("BTC_USDT", params2)  # Subscribe to BTC/USDT order

    binance_pro.connect(rt)

    logd("sleep")
    sleep_ms(rt, 10 * 60 * 1000)

    # _ = binance^
    # _ = binance_pro^


fn main() raises:
    var logger = init_logger(LogLevel.Debug, "", "")

    logd("Starting")

    # run_async_trading_thread()

    # test_monoiohttpclient()
    # test_http_get()
    # test_binance_fetch_balance()
    # test_binance()
    test_ws()

    time.sleep(1000000.0)

    destroy_logger(logger)
