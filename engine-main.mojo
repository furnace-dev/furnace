import time
from memory import UnsafePointer
from collections import Dict
from monoio_connect import (
    create_monoio_runtime,
    logt,
    logd,
    logi,
    logw,
    loge,
    Fixed,
    parse_bool,
    init_logger,
    destroy_logger,
    LogLevel,
)
from ccxt.base import (
    TradingContext,
    ExchangeId,
    Any,
    Ticker,
    OrderBook,
    Trade,
    Balance,
    Order,
    Exchangeable,
    OrderType,
    OrderSide,
    Strings,
)
from ccxt.foundation.bybit import Bybit
from ccxt.foundation.gate import Gate
from ccxt.foundation.binance import Binance
from ccxt.foundation.bitmex import BitMEX
from ccxt.foundation import (
    create_exchange_instance,
)
from ccxt.pro.gate import Gate as GatePro
from ccxt import Strategizable
from ccxt.executor import Executable, Executor
from ccxt.engine import (
    Engine,
    run,
)
from mojoenv import load_mojo_env


struct MyStrategy[E: Exchangeable](Strategizable):
    var ex: UnsafePointer[Executor[E]]
    var signal: Bool

    fn __init__[E_: Exchangeable](out self, ex: UnsafePointer[Executor[E_]]):
        self.ex = ex.bitcast[Executor[E]]()
        self.signal = False

    fn __moveinit__(out self, owned existing: Self):
        self.ex = existing.ex
        existing.ex = UnsafePointer[Executor[E]]()
        self.signal = existing.signal

    fn __del__(owned self):
        pass

    fn on_init(mut self) raises:
        logd("on_init")
        # 订阅ticker
        self.ex[].subscribe_ticker("XRP_USDT", Dict[String, Any]())

        # 订阅tickers
        var symbols = List[String]()
        symbols.append("XRP_USDT")
        symbols.append("BTC_USDT")
        self.ex[].subscribe_tickers(symbols, Dict[String, Any]())

        # 订阅order_book
        self.ex[].subscribe_order_book("XRP_USDT", Dict[String, Any]())

        # 订阅trade
        self.ex[].subscribe_trade("XRP_USDT", Dict[String, Any]())

        # 订阅balance
        self.ex[].subscribe_balance(Dict[String, Any]())

        # 订阅order
        self.ex[].subscribe_order("XRP_USDT", Dict[String, Any]())

        # 订阅my_trades
        self.ex[].subscribe_my_trades("XRP_USDT", Dict[String, Any]())

        # 获取ticker
        var ticker = self.ex[].fetch_ticker("XRP_USDT")
        logd("ticker: " + String(ticker))

    fn on_deinit(mut self) raises:
        logd("on_deinit")

    fn on_ticker(mut self, ticker: Ticker) raises:
        logd("on_ticker")
        if not self.signal:
            # 异步下单
            var params = Dict[String, Any]()
            self.ex[].create_order_async(
                "BTC_USDT",
                OrderType.Limit,
                OrderSide.Buy,
                Fixed(1.0),
                Fixed(93000),
                params,
            )
            self.signal = True

    fn on_order_book(mut self, order_book: OrderBook) raises:
        logd("on_order_book")

    fn on_trade(mut self, trade: Trade) raises:
        logd("on_trade")

    fn on_balance(mut self, balance: Balance) raises:
        logd("on_balance")

    fn on_order(mut self, order: Order) raises:
        logd("on_order")

    fn on_my_trade(mut self, trade: Trade) raises:
        logd("on_my_trade")


fn main() raises:
    var logger = init_logger(LogLevel.Debug, "", "")
    var env_vars = load_mojo_env(".env")

    var api_key = env_vars["GATEIO_API_KEY"]
    var api_secret = env_vars["GATEIO_API_SECRET"]
    var testnet = parse_bool(env_vars["GATEIO_TESTNET"])

    var config = Dict[String, Any]()

    config["api_key"] = api_key
    config["api_secret"] = api_secret
    config["testnet"] = testnet
    config["verbose"] = True

    var engine = Engine[Gate, GatePro, MyStrategy[Gate]](
        config, ExchangeId.gateio, "1", "1"
    )
    engine.start()

    # run[Gate, GatePro, MyStrategy[Gate]](
    #     config, ExchangeId.gateio, "1", "1"
    # )

    destroy_logger(logger)
