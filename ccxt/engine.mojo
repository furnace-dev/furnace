import time
from memory import UnsafePointer, ArcPointer
from collections import Dict
from algorithm.functional import parallelize, sync_parallelize
from libc.unistd.syscalls import gettid
from monoio_connect import (
    MonoioRuntimePtr,
    create_monoio_runtime,
    start_thread,
    logd,
    logi,
    logw,
    loge,
    sleep_ms,
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
    OnTicker,
    OnTickers,
    OnOrderBook,
    OnTrade,
    OnBalance,
    OnOrder,
    OnMyTrade,
    OnTickerC,
    OnTickersC,
    OnOrderBookC,
    OnTradeC,
    OnBalanceC,
    OnOrderC,
    OnMyTradeC,
)
from ccxt.base.exchangeable import Exchangeable
from ccxt.base.pro_exchangeable import ProExchangeable
from ccxt.foundation import (
    create_exchange_instance,
    initialize_exchange_instance,
)
from ccxt.pro import (
    create_pro_exchange_instance,
    initialize_pro_exchange_instance,
)
from .strategizable import Strategizable
from .executor import Executor
from ccxt.foundation._async_trading_operations import (
    run_async_trading_thread,
)

alias EnginePrivateWSRun = fn () escaping -> None
alias EnginePublicWSRun = fn () escaping -> None


fn _async_pri_ws_backend_task(context: UnsafePointer[UInt8]) -> UInt8:
    logi("_async_pri_ws_backend_task")
    # var ptr = context.bitcast[EnginePrivateWSRun]()
    # ptr[]()
    return 0


fn _async_pub_ws_backend_task(context: UnsafePointer[UInt8]) -> UInt8:
    logi("_async_pub_ws_backend_task")
    # var rt = create_monoio_runtime()
    # var ptr = context.bitcast[EnginePublicWSRun]()
    # ptr[]()
    return 0


fn on_order(trading_context: TradingContext, order: Order) -> None:
    logd("on_order start")
    logd("trading_context: " + str(trading_context))
    logd("order: " + str(order))
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


fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    logi("on_ticker: " + str(trading_context) + " " + str(ticker))

    # if not flag:
    #     flag = True
    #     try:
    #         var params1 = Dict[String, Any]()
    #         var ok = gate_client[].create_order_async(
    #             "BTC_USDT",
    #             OrderType.Limit,
    #             OrderSide.Buy,
    #             Fixed(1.0),
    #             Fixed(93000),
    #             params1,
    #         )
    #         logd("ok: " + str(ok))
    #     except e:
    #         logd(str(e))


struct Engine[T: Exchangeable, W: ProExchangeable, S: Strategizable](Movable):
    var _config: Dict[String, Any]
    var _trading_context: TradingContext
    var _rt: MonoioRuntimePtr
    var _exchange: UnsafePointer[T]
    var _private_ws: UnsafePointer[W]
    var _public_ws: UnsafePointer[W]
    var _executor: UnsafePointer[Executor[T]]
    var _strategy: UnsafePointer[S]
    var _on_ticker_c: UnsafePointer[OnTickerC]
    var _running: Bool

    fn __init__(
        out self,
        config: Dict[String, Any],
        exchange_id: ExchangeId,
        account_id: String,
        trader_id: String,
    ):
        self._config = config
        self._rt = create_monoio_runtime()
        self._exchange = UnsafePointer[T].alloc(1)
        self._trading_context = TradingContext(
            exchange_id=exchange_id, account_id=account_id, trader_id=trader_id
        )
        initialize_exchange_instance(
            self._exchange, config, self._trading_context, self._rt
        )
        self._private_ws = UnsafePointer[W].alloc(1)
        self._public_ws = UnsafePointer[W].alloc(1)
        initialize_pro_exchange_instance(
            self._private_ws, config, self._trading_context
        )
        initialize_pro_exchange_instance(
            self._public_ws, config, self._trading_context
        )
        self._strategy = UnsafePointer[S].alloc(1)
        __get_address_as_uninit_lvalue(self._strategy.address) = S()
        self._executor = UnsafePointer[Executor[T]].alloc(1)
        __get_address_as_uninit_lvalue(self._executor.address) = Executor(
            self._exchange
        )
        self._strategy[].setup(self._executor)
        self._on_ticker_c = UnsafePointer[OnTickerC].alloc(1)
        self._running = False

    fn __moveinit__(out self, owned existing: Self):
        self._config = existing._config
        self._trading_context = existing._trading_context
        self._rt = existing._rt
        self._exchange = existing._exchange
        self._private_ws = existing._private_ws
        self._public_ws = existing._public_ws
        self._executor = existing._executor
        self._strategy = existing._strategy
        self._on_ticker_c = existing._on_ticker_c
        self._running = existing._running

    # fn get_private_ws_run(self) -> EnginePrivateWSRun:
    #     var ptr = UnsafePointer.address_of(self)

    #     fn wrapper():
    #         ptr[].__on_private_ws_run()

    #     return wrapper

    # fn get_public_ws_run(self) -> EnginePublicWSRun:
    #     var ptr = UnsafePointer.address_of(self)

    #     fn wrapper():
    #         ptr[].__on_public_ws_run()

    #     return wrapper

    fn __on_private_ws_run(mut self) raises:
        logd("__on_private_ws_run")

    fn __on_public_ws_run(mut self) raises:
        logd("__on_public_ws_run")
        var rt = create_monoio_runtime()

        var ws = W(self._config, self._trading_context)

        var on_ticker = self._on_ticker_c.take_pointee()

        # var on_ticker = self.get_on_ticker()
        ws.set_on_ticker(on_ticker^)
        # ws.set_on_order(self.get_on_order())

        # Subscribe to real-time ticker data
        var params1 = Dict[String, Any]()
        ws.subscribe_ticker(
            "BTC_USDT", params1
        )  # Subscribe to BTC/USDT real-time ticker

        # Subscribe to order data
        # var params2 = Dict[String, Any]()
        # ws.subscribe_order("BTC_USDT", params2)  # Subscribe to BTC/USDT order

        ws.connect(rt)

    fn get_on_ticker(self) -> OnTickerC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, ticker: Ticker):
            ptr[].__on_ticker(trading_context, ticker)

        return wrapper

    fn get_on_order(self) -> OnOrderC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, order: Order):
            ptr[].__on_order(trading_context, order)

        return wrapper

    fn __on_ticker(
        mut self, trading_context: TradingContext, ticker: Ticker
    ) -> None:
        logi("on_ticker: " + str(trading_context) + " " + str(ticker))

    fn __on_order(
        mut self, trading_context: TradingContext, order: Order
    ) -> None:
        logi("on_order: " + str(trading_context) + " " + str(order))

    fn init(mut self) raises:
        self._strategy[].on_init()
        var ot = self.get_on_ticker()
        self._on_ticker_c.init_pointee_move(ot^)
        self._running = True

    fn stop(self) raises:
        pass


fn run_engine[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) raises:
    run_async_trading_thread()

    # not work: why?
    # try:
    #     engine.init()
    # except e:
    #     logw("init engine error: " + str(e))
    #     return

    @parameter
    fn run_loop(n: Int) -> None:
        logi("task " + str(n) + " thread id: " + str(gettid()))
        if n == 0:
            try:
                engine.__on_private_ws_run()
            except e:
                print(str(e))
        elif n == 1:
            try:
                engine.__on_public_ws_run()
            except e:
                print(str(e))

    parallelize[run_loop](2)

    logi("engine done.")


fn create_closure[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](ptr: UnsafePointer[Engine[T, W, S], alignment=1]) -> EnginePrivateWSRun:
    fn closure() escaping -> None:
        try:
            ptr[].__on_private_ws_run()
        except e:
            print(str(e))

    return closure
