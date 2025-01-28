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
    run_engine,
)
from mojoenv import load_mojo_env


struct MyStrategy[E: Executable](Strategizable):
    var ex: UnsafePointer[E]
    var signal: Bool

    fn __init__(out self):
        self.ex = UnsafePointer[E]()
        self.signal = False

    fn __moveinit__(out self, owned existing: Self):
        self.ex = existing.ex
        existing.ex = UnsafePointer[E]()
        self.signal = existing.signal

    fn __del__(owned self):
        pass

    fn setup[E_: Executable](mut self, exchange: UnsafePointer[E_]):
        self.ex = exchange.bitcast[E]()

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
        logd("ticker: " + str(ticker))

    fn on_deinit(mut self) raises:
        pass

    fn on_ticker(mut self, ticker: Ticker) raises:
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
        pass

    fn on_trade(mut self, trade: Trade) raises:
        pass

    fn on_balance(mut self, balance: Balance) raises:
        pass

    fn on_order(mut self, order: Order) raises:
        pass

    fn on_my_trade(mut self, trade: Trade) raises:
        pass


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

    var engine = Engine[Gate, GatePro, MyStrategy[Executor[Gate]]](
        config, ExchangeId.gateio, "1", "1"
    )
    engine.init()
    run_engine(engine)

    destroy_logger(logger)
