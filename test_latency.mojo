from sys._build import is_debug_build
from collections import Dict, List
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
    OrderBook,
    OrderbookEntry,
    ExchangeId,
    TradingContext,
)
from ccxt.foundation.binance import Binance
from time import sleep, perf_counter_ns


fn get_order_book_mid(order_book: OrderBook) raises -> Fixed:
    if len(order_book.asks) > 0 and len(order_book.bids) > 0:
        var ask_price = order_book.asks[0].price
        var bid_price = order_book.bids[0].price
        return (ask_price + bid_price) / Fixed(2.0)
    return Fixed(0.0)


fn calculate_percentiles(
    mut data: List[Float64], percentiles: List[Int]
) -> Dict[Int, Float64]:
    # 首先对数据进行排序
    var results = Dict[Int, Float64]()
    for p in percentiles:
        var k = (len(data) - 1) * (float(p[]) / 100.0)
        var f = int(k)  # 下标索引
        var c = f + 1  # 上标索引

        if c >= len(data):
            results[p[]] = data[f]
        else:
            var d0 = data[f] * (Float64(c) - k)
            var d1 = data[c] * (k - Float64(f))
            results[p[]] = d0 + d1
    return results


fn main() raises:
    # 初始化日志和配置
    var logger = init_logger(LogLevel.Debug, "", "")
    var env_vars = load_mojo_env(".env")
    var api_key = env_vars["BINANCE_API_KEY"]
    var api_secret = env_vars["BINANCE_API_SECRET"]
    var testnet = parse_bool(env_vars["BINANCE_TESTNET"])

    # 初始化交易上下文和API
    var config = Dict[String, Any]()
    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet

    var symbol = String("XRPUSDT")
    var trading_context = TradingContext(
        exchange_id=ExchangeId.binance, account_id="zsyhsapi", trader_id="1"
    )

    var rt = create_monoio_runtime()
    var api = Binance(config, trading_context, rt)

    # 获取市场数据
    var params = Dict[String, Any]()
    var order_book = api.fetch_order_book(symbol, None, params)
    var mid_price = get_order_book_mid(order_book)

    # 设置订单参数
    var price = (mid_price * Fixed(0.8)).round_to_fractional(
        Fixed(0.0001)
    )  # 使用中间价格的80%
    var amount = Fixed(3)  # 使用最小交易量，避免实际成交
    var results = List[Float64]()

    var rounds = 600
    logd("rounds: " + str(rounds))
    # 测试下单和撤单延迟
    for i in range(rounds):
        try:
            # 创建限价买单
            var order = api.create_order(
                symbol, OrderType.Limit, OrderSide.Buy, amount, price, params
            )

            # 记录开始时间
            var start_time = perf_counter_ns()

            # 撤销订单
            _ = api.cancel_order(order.id, symbol, params)

            # 计算延迟
            var end_time = perf_counter_ns()
            var elapsed = Float64(end_time - start_time) / 1_000_000.0  # 转换为毫秒
            # 跳过第一次请求的数据
            if i > 0:
                results.append(elapsed)

            logd("Order " + str(i) + " RTT: " + str(elapsed) + "ms")
            logd(String(",").join(results))
        except e:
            logd("Error: " + str(e))
            # try:
            #     _ = api.cancel_all_orders(symbol, params)
            # except:
            #     logd("Error cancelling orders")

        # 每次测试间隔10秒
        sleep_ms(rt, 10000)

    # 计算平均延迟
    var total: Float64 = 0.0
    for i in range(len(results)):
        total += results[i]

    if len(results) > 0:
        var avg_rtt = total / Float64(len(results))
        logd("Successfully tested " + str(len(results)) + " orders")
        logd("Average round-trip time: " + str(avg_rtt) + " milliseconds")

        # Calculate and print min/max values
        sort(results)
        var max_latency = results[-1]
        var min_latency = results[0]

        logd("Max: " + str(max_latency) + "ms")
        logd("Min: " + str(min_latency) + "ms")

        var percentiles = List[Int]()
        percentiles.append(5)
        percentiles.append(15)
        percentiles.append(90)
        var stats = calculate_percentiles(results, percentiles)
        for p in percentiles:
            logd(str(p[]) + "%: " + str(stats[p[]]) + "ms")

    # # 清理所有未完成订单
    # try:
    #     _ = api.cancel_all_orders(symbol, params)
    # except:
    #     logd("Error cancelling final orders")
