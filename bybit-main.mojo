import time
from collections import Dict
from os import getenv
from testing import assert_equal, assert_true
from memory import UnsafePointer, stack_allocation
from mojoenv import load_mojo_env
from monoio_connect import (
    create_monoio_runtime,
    parse_bool,
    logt,
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
from ccxt.pro.bybit import Bybit as BybitPro
from ccxt.foundation._async_trading_operations import (
    run_async_trading_thread,
)


fn on_order(trading_context: TradingContext, order: Order) -> None:
    logd("on_order start")
    # logd("trading_context: " + String(trading_context))
    # logd("order: " + String(order))
    logd("exchange_id: " + String(trading_context.exchange_id))
    logd("account_id: " + trading_context.account_id)
    logd("trader_id: " + trading_context.trader_id)
    logd("=============")
    logd("id: " + order.id)
    logd("symbol: " + order.symbol)
    logd("type: " + order.type)
    logd("side: " + String(order.side))
    logd("amount: " + String(order.amount))
    logd("price: " + String(order.price))
    logd("on_order end")


fn test_bybit() raises:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BYBIT_API_KEY"]
    var api_secret = env_vars["BYBIT_API_SECRET"]
    var testnet = parse_bool(env_vars["BYBIT_TESTNET"])

    var rt = create_monoio_runtime()
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    config["verbose"] = True
    # config["base_url"] = "https://api.bytick.com"

    var trading_context = TradingContext(
        exchange_id=ExchangeId.bybit, account_id="1", trader_id="1"
    )
    var bybit = Bybit(config, trading_context, rt)
    var params = Dict[String, Any]()

    bybit.set_on_order(on_order)

    var symbol = "XRPUSDT"

    # var markets = bybit.fetch_markets(params)
    # for market in markets:
    #     logd(String(market[].value()))

    # var currencies = bybit.fetch_currencies(params)
    # for currency in currencies:
    #     print(String(currency[].value()))

    var ticker = bybit.fetch_ticker(symbol)
    logd(String(ticker))

    # var symbols = List[String](capacity=2)
    # symbols.append(symbol)
    # symbols.append("ETHUSDT")
    # var tickers = bybit.fetch_tickers(symbols, params)
    # for ticker in tickers:
    #     logd(String(ticker[]))

    # var order_book = bybit.fetch_order_book(symbol, 10, params)
    # logd(String(order_book))

    # logd("len(asks)=" + String(len(order_book.asks)))
    # logd("len(bids)=" + String(len(order_book.bids)))
    # logd("ask: " + String(order_book.asks[0]))
    # logd("bid: " + String(order_book.bids[0]))

    # var trades = bybit.fetch_trades(symbol, None, None, params)
    # for trade in trades:
    #     logd(String(trade))

    # var balances = bybit.fetch_balance(params)
    # logd(String(balances))
    # for k_v in balances.data.items():
    #     logd("key: " + k_v[].key)
    #     logd("value: " + String(k_v[].value))

    # sleep_ms(rt, 10)

    var mid_price = (
        (ticker.high + ticker.low) / Fixed(2) * Fixed(0.9)
    ).round_to_fractional(Fixed(0.0001))
    logd("mid_price: " + String(mid_price))

    var qty = (Fixed(10.0) / mid_price).round_to_fractional(Fixed(1))

    # var order = bybit.create_order(
    #     symbol,
    #     OrderType.Limit,
    #     OrderSide.Buy,
    #     qty,
    #     mid_price,
    #     params,
    # )
    # logd(String(order))

    # var order_id = order.id
    var order_id = "d7cae7eb-3c98-4116-85a8-b5857c226a8b"

    # var order_result = bybit.fetch_order(order_id, String(symbol), params)
    # logd(String(order_result))

    # var orders = bybit.fetch_orders(String(symbol), None, 5, params)
    # logd("len(orders)=" + String(len(orders)))
    # for order in orders:
    #     logd(String(order[]))

    var open_orders = bybit.fetch_open_orders(
        String(symbol), None, None, params
    )
    logd("len(open_orders)=" + String(len(open_orders)))
    for order in open_orders:
        logd(String(order[]))

    # OK
    # var cancel_order = bybit.cancel_order(
    #     order_id, String(symbol), params
    # )
    # logd(String(cancel_order))

    logd("sleep")

    sleep_ms(rt, 10 * 60 * 1000)

    _ = bybit^


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + String(trading_context) + " " + String(ticker))


# ws
fn test_ws() raises:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BYBIT_API_KEY"]
    var api_secret = env_vars["BYBIT_API_SECRET"]
    var testnet = parse_bool(env_vars["BYBIT_TESTNET"])

    var rt = create_monoio_runtime()
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    config["verbose"] = True
    config["is_private"] = True

    var trading_context = TradingContext(
        exchange_id=ExchangeId.bybit, account_id="1", trader_id="1"
    )

    var bybit_pro = BybitPro(config, trading_context)
    bybit_pro.set_on_ticker(on_ticker)
    bybit_pro.set_on_order(on_order)

    # Subscribe to order book depth data
    # var params0 = Dict[String, Any]()
    # params0["interval"] = "100ms"  # Update interval is 100ms
    # bybit_pro.subscribe_order_book("BTC_USDT", params0)  # Subscribe to BTC/USDT order book

    # Subscribe to real-time ticker data
    # var params1 = Dict[String, Any]()
    # bybit_pro.subscribe_ticker("XRPUSDT", params1)

    # Subscribe to order data
    var params2 = Dict[String, Any]()
    var symbol = "XRPUSDT"
    bybit_pro.subscribe_order(symbol, params2)  # Subscribe to XRP/USDT order
    bybit_pro.subscribe_balance(params2)
    bybit_pro.subscribe_my_trades(symbol, params2)

    bybit_pro.connect(rt)

    logd("sleep")
    sleep_ms(rt, 10 * 60 * 1000)

    _ = bybit_pro^


fn main() raises:
    var logger = init_logger(LogLevel.Debug, "", "")

    logd("Starting")

    # run_async_trading_thread()

    # test_bybit()
    test_ws()

    time.sleep(1000000.0)

    destroy_logger(logger)
