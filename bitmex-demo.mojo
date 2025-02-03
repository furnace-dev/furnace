from sys._build import is_debug_build
import time
from collections import Dict
from os import getenv
from testing import assert_equal
from memory import UnsafePointer, stack_allocation
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
    order_decorator,
)
from ccxt.foundation.bitmex import BitMEX
from mojoenv import load_mojo_env


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
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    config["verbose"] = True

    var trading_context = TradingContext(
        exchange_id=ExchangeId.bitmex, account_id="1", trader_id="1"
    )
    var bm = BitMEX(config, trading_context)
    var params = Dict[String, Any]()

    bm.set_on_order(order_decorator(on_order))

    # var markets = bm.fetch_markets(params)
    # for market in markets:
    #     print(str(market[].value()))

    # var currencies = bm.fetch_currencies(params)
    # for currency in currencies:
    #     print(str(currency[].value()))

    # var ticker = bm.fetch_ticker("XRPUSDT")
    # logd(str(ticker))

    # var symbols = List[String](capacity=2)
    # symbols.append("BTC_USDT")
    # symbols.append("ETH_USDT")
    # var tickers = bm.fetch_tickers(symbols, params)
    # for ticker in tickers:
    #     logd(str(ticker[]))

    # var order_book = bm.fetch_order_book("XRPUSDT", 10, params)
    # logd(str(order_book))

    # logd("len(asks)=" + str(len(order_book.asks)))
    # logd("len(bids)=" + str(len(order_book.bids)))
    # logd("ask: " + str(order_book.asks[0]))
    # logd("bid: " + str(order_book.bids[0]))

    # var trades = bm.fetch_trades("XRPUSDT", None, None, params)
    # for trade in trades:
    #     logd(str(trade[]))

    # var balance = bm.fetch_balance(params)
    # logd(str(balance))

    var order = bm.create_order(
        "XRPUSDT",
        OrderType.Limit,
        OrderSide.Buy,
        Fixed(1.0),
        Fixed(0.2000),
        params,
    )
    logd(str(order))

    # _ = bm.create_order_async(
    #     "BTC_USDT",
    #     OrderType.Limit,
    #     OrderSide.Buy,
    #     Fixed(1.0),
    #     Fixed(93000),
    #     params,
    # )

    # logd("cancel_order")

    # var cancel_order = bm.cancel_order(
    #     String("58828270140601928"), String("BTC_USDT"), params
    # )
    # logd(str(cancel_order))
    # logd("cancel_order end")

    logd("sleep")

    time.sleep(10000.0)

    _ = bm^


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + str(trading_context) + " " + str(ticker))


# ws
fn test_ws(api_key: String, api_secret: String) raises -> None:
    pass
    # var config_pro = Dict[String, Any]()

    # config_pro["api_key"] = api_key
    # config_pro["api_secret"] = api_secret
    # config_pro["testnet"] = True
    # config_pro["settle"] = "usdt"

    # var trading_context = TradingContext(
    #     exchange_id=ExchangeId.bitmex, account_id="1", trader_id="1"
    # )
    # var gate_pro = GatePro(config_pro, trading_context)
    # gate_pro.set_on_ticker(on_ticker)
    # gate_pro.set_on_order(on_order)

    # var ioc = seq_asio_ioc()
    # seq_asio_run_ex(ioc, -1, False)

    # gate_pro.connect()

    # time.sleep(3.0)

    # print("subscribe")

    # # var params = Dict[String, Any]()
    # # params["interval"] = "100ms"
    # # gate_pro.subscribe_order_book("BTC_USDT", params)

    # var params = Dict[String, Any]()
    # gate_pro.subscribe_ticker("BTC_USDT", params)

    # print("subscribe done")

    # # var req_id = seq_nanoid()
    # # gate_pro.login("header", req_id)

    # # time.sleep(3.0)

    # # var params = Dict[String, Any]()
    # # gate_pro.subscribe_order("BTC_USDT", params)

    # time.sleep(1000000.0)

    # _ = gate_pro^


fn main() raises:
    _ = init_logger(LogLevel.Debug, "", "")

    logi("start")

    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BITMEX_API_KEY"]
    var api_secret = env_vars["BITMEX_API_SECRET"]
    var testnet = parse_bool(env_vars["BITMEX_TESTNET"])

    test_rest(api_key, api_secret, testnet)
    # test_ws(api_key, api_secret)

    time.sleep(10000.0)
