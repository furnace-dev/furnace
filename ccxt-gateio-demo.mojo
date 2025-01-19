import time
from sys._build import is_debug_build
from collections import Dict
from os import getenv
from testing import assert_equal, assert_true
from memory import UnsafePointer, stack_allocation
from mojoenv import load_mojo_env
from monoio_connect import *
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
from ccxt.foundation.gate import Gate
from ccxt.pro.gate import Gate as GatePro


fn test_http_client_post() raises -> None:
    # var base_url = "https://api.gateio.ws" if not testnet else "https://fx-api-testnet.gateio.ws"
    var base_url = "https://httpbin.org"
    var options = HttpClientOptions(base_url)
    var client = HttpClient(options)
    var full_path = "/post"
    var method = Method.METHOD_POST
    var headers = Headers()
    headers["Content-Type"] = "application/json"
    headers["Accept"] = "application/json"
    var payload = String("hello")
    var response = client.request(full_path, method, headers, payload)
    logd(response.text)


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


fn test_rest(api_key: String, api_secret: String, testnet: Bool) raises -> None:
    var rt = create_monoio_runtime()
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet

    var trading_context = TradingContext(
        exchange_id=ExchangeId.gateio, account_id="1", trader_id="1"
    )
    var gate = Gate(config, trading_context, rt)
    var params = Dict[String, Any]()

    gate.set_on_order(on_order)

    # var markets = gate.fetch_markets(params)
    # for market in markets:
    #     print(str(market))

    # var currencies = gate.fetch_currencies(params)
    # for currency in currencies:
    #     print(str(currency[].value()))

    # var ticker = gate.fetch_ticker("BTC_USDT")
    # logd(str(ticker))

    # var symbols = List[String](capacity=2)
    # symbols.append("BTC_USDT")
    # symbols.append("ETH_USDT")
    # var tickers = gate.fetch_tickers(symbols, params)
    # for ticker in tickers:
    #     logd(str(ticker[]))

    # var order_book = gate.fetch_order_book("BTC_USDT", 10, params)
    # logd(str(order_book))

    # logd("len(asks)=" + str(len(order_book.asks)))
    # logd("len(bids)=" + str(len(order_book.bids)))
    # logd("ask: " + str(order_book.asks[0]))
    # logd("bid: " + str(order_book.bids[0]))

    # var trades = gate.fetch_trades("BTC_USDT", None, None, params)
    # for trade in trades:
    #     logd(str(trade))

    # var balance = gate.fetch_balance(params)
    # logd(str(balance))

    # monoio_sleep_ms(rt, 10)

    logd("create_order")
    try:
        var order = gate.create_order(
            "BTC_USDT",
            OrderType.Limit,
            OrderSide.Buy,
            Fixed(1.0),
            Fixed(93000),
            params,
        )
        logd(str(order))
    except e:
        logd("create_order error: " + str(e))
    logd("create_order end")

    # try:
    #     _ = gate.create_order_async(
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

    # var cancel_order = gate.cancel_order(
    #     String("58828270140601928"), String("BTC_USDT"), params
    # )
    # logd(str(cancel_order))
    # logd("cancel_order end")

    logd("sleep")

    sleep_ms(rt, 10 * 60 * 1000)

    # time.sleep(1000000.0)

    # gate.keep_alive()
    _ = gate^


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + str(trading_context) + " " + str(ticker))


fn thread_run(arg: UnsafePointer[UInt8]) -> UInt8:
    var rt = create_monoio_runtime()
    var gate_pro = arg.bitcast[GatePro]()
    print("start connect")
    try:
        gate_pro[].connect(rt)
    except err:
        print(str(err))
    print("connect done")
    return 0


fn thread_run_wrap[T: AnyType](arg: UnsafePointer[UInt8]) -> UInt8:
    var rt = create_monoio_runtime()
    var gate_pro = arg.bitcast[GatePro]()
    print("start connect")
    try:
        gate_pro[].connect(rt)
    except err:
        print(str(err))
    print("connect done")
    return 0


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


fn test_sign() raises:
    # method_str: POST
    # path_: /api/v4/futures/usdt/orders
    # query:
    # payload: {"contract":"BTC_USDT","size":1,"price":"93000","tif":"gtc"}
    # ts: 1735736524
    # sign: 8c759c5cb2ae052e0868a120c759279e14a8fff5bba26ac4e1c9f202e124fe83baee060309d3144da9be96057ddf9451995725b3a8c04d3afa4876ec8a540ce9
    var method_str = "POST"
    var path_ = "/api/v4/futures/usdt/orders"
    var query = ""
    var payload = '{"contract":"BTC_USDT","size":1,"price":"93000","tif":"gtc"}'
    var ts = 1735736524
    var sign = "8c759c5cb2ae052e0868a120c759279e14a8fff5bba26ac4e1c9f202e124fe83baee060309d3144da9be96057ddf9451995725b3a8c04d3afa4876ec8a540ce9"
    var trading_context = TradingContext(
        exchange_id=ExchangeId.gateio, account_id="1", trader_id="1"
    )
    var config = Dict[String, Any]()

    var api_key = "54f938b79e12aa343242ba1d940196c5"
    var api_secret = "3a98ab4e74b5a02acd5156184bf0e5ace7df76f5bafaa02ff3aedc4c22452bfe"
    var testnet = True
    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    var gate = Gate(config, trading_context)
    var sign_result = gate._sign_payload(
        method_str, path_, query, payload, str(ts)
    )
    logd("sign_result: " + sign_result)
    assert_equal(sign_result, sign)


fn main() raises:
    var logger = init_logger(LogLevel.Debug, "", "")

    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["GATEIO_API_KEY"]
    var api_secret = env_vars["GATEIO_API_SECRET"]
    var testnet = parse_bool(env_vars["GATEIO_TESTNET"])

    # test_http_client_post()

    # test_sign()
    test_rest(api_key, api_secret, testnet)
    # test_ws(api_key, api_secret, testnet)

    time.sleep(1000000.0)
