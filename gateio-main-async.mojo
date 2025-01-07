from os import abort
from collections import Dict
from os import getenv
from time import perf_counter_ns
from testing import assert_equal, assert_true
from memory import UnsafePointer, stack_allocation
from sys.ffi import _Global
from mojoenv import load_mojo_env
from monoio_connect import *
from ccxt.base.types import Any, OrderType, OrderSide, Num, Order, Ticker
from ccxt.foundation.bybit import Bybit
from ccxt.foundation.gate import Gate
from ccxt.pro.gate import Gate as GatePro
from ccxt.base.pro_exchangeable import TradingContext
from monoio_connect.pthread import *
from monoio_connect import *

alias GATE_CLIENT = _Global[
    "GATE_CLIENT",
    Gate,
    _init_gate,
]


fn _init_gate() -> Gate:
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars.get("GATEIO_API_KEY").value()
    var api_secret = env_vars.get("GATEIO_API_SECRET").value()
    var testnet = parse_bool(env_vars.get("GATEIO_TESTNET").value())

    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet

    var trading_context = TradingContext(
        exchange_id="gate", account_id="1", trader_id="1"
    )
    var rt = create_monoio_runtime()
    return Gate(config, trading_context, rt, debug=False)


fn gate_client_ptr() -> UnsafePointer[Gate]:
    return GATE_CLIENT.get_or_create_ptr()


alias _CHANNEL = _Global[
    "_CHANNEL",
    ChannelPtr,
    _init_channel,
]


fn _init_channel() -> ChannelPtr:
    return create_channel(2, 1024)


fn channel_ptr() -> UnsafePointer[ChannelPtr]:
    return _CHANNEL.get_or_create_ptr()


fn on_order(trading_context: TradingContext, order: Order) -> None:
    logd("on_order start")
    # logd("trading_context: " + str(trading_context))
    # logd("order: " + str(order))
    logd("exchange_id: " + trading_context.exchange_id)
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


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + str(trading_context) + " " + str(ticker))


fn run() raises:
    logd("run")
    bind_to_cpu_set(0)
    var rt = create_monoio_runtime()

    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["GATEIO_API_KEY"]
    var api_secret = env_vars["GATEIO_API_SECRET"]
    var testnet = parse_bool(env_vars["GATEIO_TESTNET"])

    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet

    var trading_context = TradingContext(
        exchange_id="gate", account_id="1", trader_id="1"
    )
    var gate = Gate(config, trading_context, rt, debug=False)
    var params = Dict[String, Any]()

    gate.set_on_order(on_order)

    # 获取市场
    # var market = gate.fetch_markets(params)
    # for m in market:
    #     logd(str(m[].value()))

    # 获取币种
    # var currencies = gate.fetch_currencies(params)
    # for c in currencies:
    #     logd(str(c[].value()))

    # 获取ticker
    # var ticker = gate.fetch_ticker("BTC_USDT")
    # logd(str(ticker))

    # 获取tickers
    # var symbols = List[String](capacity=2)
    # symbols.append("BTC_USDT")
    # var tickers = gate.fetch_tickers(symbols, params)
    # for t in tickers:
    #     logd(str(t[]))

    # 获取order_book
    # var order_book = gate.fetch_order_book("BTC_USDT", 10, params)
    # for a in order_book.asks:
    #     logd("a: " + str(a[]))
    # for b in order_book.bids:
    #     logd("b: " + str(b[]))

    # 获取trades
    # var trades = gate.fetch_trades("BTC_USDT", None, None, params)
    # for t in trades:
    #     logd(str(t[]))

    # 获取balance
    # var balance = gate.fetch_balance(params)
    # logd(str(balance))

    # while True:
    #     try:
    #         var start = perf_counter_ns()
    #         var ticker = gate.fetch_ticker("BTC_USDT")
    #         var end = perf_counter_ns()
    #         # logd(String.write("fetch_ticker Time: ", (end - start) / 1000000, "ms"))
    #         # logd(str(ticker))
    #     except e:
    #         logd(str(e))

    #     # 休息
    #     monoio_sleep_ms(rt, 200)

    # try:
    #     _ = gate.submit_order(
    #         "BTC_USDT",
    #         OrderType.Limit,
    #         OrderSide.Buy,
    #         Fixed(1.0),
    #         Fixed(93000),
    #         params,
    #     )
    # except e:
    #     logd("submit_order error: " + str(e))

    # logi("sleep")


fn gate_client_backend() raises -> None:
    logd("gate_client_backend run")
    # 设置cpu
    bind_to_cpu_set(0)
    # 初始化客户端
    gate_client_ptr()[].submit_order(
        "BTC_USDT",
        OrderType.Limit,
        OrderSide.Buy,
        Fixed(1.0),
        Fixed(93000),
        Dict[String, Any](),
    )


fn main() raises:
    var logger = init_logger(LogLevel.Debug, "", "")
    # run()
    time.sleep(1000000.0)
    destroy_logger(logger)

    # test_rest(api_key, api_secret, testnet)
    # time.sleep(1000000.0)
