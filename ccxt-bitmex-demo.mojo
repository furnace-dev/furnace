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
)
from ccxt.foundation.bitmex import BitMEX


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


fn test_rest(api_key: String, api_secret: String) raises -> None:
    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = True

    var trading_context = TradingContext(
        exchange_id=ExchangeId.bitmex, account_id="1", trader_id="1"
    )
    var bm = BitMEX(config, trading_context)
    var params = Dict[String, Any]()

    print("1000")
    bm.set_on_order(on_order)
    print("1001")

    var markets = bm.fetch_markets(params)
    print("1002")
    for market in markets:
        print(str(market))
    # https://api.gateio.ws/api/v4/spot/currencies
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

    # logd("create_order")
    # try:
    #     var order = gate.create_order(
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

    # _ = bm.create_order_async(
    #     "BTC_USDT",
    #     OrderType.Limit,
    #     OrderSide.Buy,
    #     Fixed(1.0),
    #     Fixed(93000),
    #     params,
    # )

    # logd("cancel_order")

    # var cancel_order = gate.cancel_order(
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
    #     exchange_id=ExchangeId.gateio, account_id="1", trader_id="1"
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

    var api_key = "54f938b79e12aa343242ba1d940196c5"
    var api_secret = "3a98ab4e74b5a02acd5156184bf0e5ace7df76f5bafaa02ff3aedc4c22452bfe"

    test_rest(api_key, api_secret)
    # test_ws(api_key, api_secret)

    time.sleep(10000.0)
