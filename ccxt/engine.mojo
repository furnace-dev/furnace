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
    OrderBook,
    Trade,
    Balance,
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
    ticker_decorator,
    tickers_decorator,
    orderbook_decorator,
    trade_decorator,
    balance_decorator,
    order_decorator,
    mytrade_decorator,
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
from ccxt.foundation._base import (
    empty_on_ticker,
    empty_on_tickers,
    empty_on_order_book,
    empty_on_trade,
    empty_on_balance,
    empty_on_order,
    empty_on_my_trade,
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


struct Engine[T: Exchangeable, W: ProExchangeable, S: Strategizable](Movable):
    var _config: Dict[String, Any]
    var _trading_context: TradingContext
    var _rt: MonoioRuntimePtr
    var _exchange: UnsafePointer[T]
    var _private_ws: UnsafePointer[W]
    var _public_ws: UnsafePointer[W]
    var _executor: UnsafePointer[Executor[T]]
    var _strategy: UnsafePointer[S]
    var _on_ticker_c: UnsafePointer[OnTickerC, alignment=1]
    var _on_tickers_c: UnsafePointer[OnTickersC, alignment=1]
    var _on_order_book_c: UnsafePointer[OnOrderBookC, alignment=1]
    var _on_trade_c: UnsafePointer[OnTradeC, alignment=1]
    var _on_balance_c: UnsafePointer[OnBalanceC, alignment=1]
    var _on_order_c: UnsafePointer[OnOrderC, alignment=1]
    var _on_my_trade_c: UnsafePointer[OnMyTradeC, alignment=1]
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
        self._on_ticker_c = UnsafePointer[OnTickerC, alignment=1].alloc(1)
        self._on_tickers_c = UnsafePointer[OnTickersC, alignment=1].alloc(1)
        self._on_order_book_c = UnsafePointer[OnOrderBookC, alignment=1].alloc(
            1
        )
        self._on_trade_c = UnsafePointer[OnTradeC, alignment=1].alloc(1)
        self._on_balance_c = UnsafePointer[OnBalanceC, alignment=1].alloc(1)
        self._on_order_c = UnsafePointer[OnOrderC, alignment=1].alloc(1)
        self._on_my_trade_c = UnsafePointer[OnMyTradeC, alignment=1].alloc(1)
        self._running = False

    fn __copyinit__(out self, existing: Self):
        self._config = existing._config
        self._trading_context = existing._trading_context
        self._rt = existing._rt
        self._exchange = existing._exchange
        self._private_ws = existing._private_ws
        self._public_ws = existing._public_ws
        self._executor = existing._executor
        self._strategy = existing._strategy
        self._on_ticker_c = existing._on_ticker_c
        self._on_tickers_c = existing._on_tickers_c
        self._on_order_book_c = existing._on_order_book_c
        self._on_trade_c = existing._on_trade_c
        self._on_balance_c = existing._on_balance_c
        self._on_order_c = existing._on_order_c
        self._on_my_trade_c = existing._on_my_trade_c
        self._running = existing._running

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
        self._on_tickers_c = existing._on_tickers_c
        self._on_order_book_c = existing._on_order_book_c
        self._on_trade_c = existing._on_trade_c
        self._on_balance_c = existing._on_balance_c
        self._on_order_c = existing._on_order_c
        self._on_my_trade_c = existing._on_my_trade_c
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

        # var self_ptr = ArcPointer[Self](self)

        # fn _on_ticker(trading_context: TradingContext, ticker: Ticker):
        #     self_ptr[].__on_ticker(trading_context, ticker)

        # ws.set_on_ticker(_on_ticker)

        var on_ticker = self._on_ticker_c.take_pointee()
        var on_tickers = self._on_tickers_c.take_pointee()
        var on_order_book = self._on_order_book_c.take_pointee()
        var on_trade = self._on_trade_c.take_pointee()
        var on_balance = self._on_balance_c.take_pointee()
        var on_order = self._on_order_c.take_pointee()
        var on_my_trade = self._on_my_trade_c.take_pointee()

        ws.set_on_ticker(on_ticker)
        ws.set_on_tickers(on_tickers)
        ws.set_on_order_book(on_order_book)
        ws.set_on_trade(on_trade)
        ws.set_on_balance(on_balance)
        ws.set_on_order(on_order)
        ws.set_on_my_trade(on_my_trade)

        # Subscribe to real-time ticker data
        # var params1 = Dict[String, Any]()
        # ws.subscribe_ticker(
        #     "BTC_USDT", params1
        # )  # Subscribe to BTC/USDT real-time ticker

        # # ticker
        # for item in self._executor[]._ticker_subscriptions:
        #     ws.subscribe_ticker(item[][0], item[][1])

        # # order book
        # for item in self._executor[]._order_book_subscriptions:
        #     ws.subscribe_order_book(item[][0], item[][1])

        # # trade
        # for item in self._executor[]._trade_subscriptions:
        #     ws.subscribe_trade(item[][0], item[][1])

        # # balance
        # for item in self._executor[]._balance_subscriptions:
        #     ws.subscribe_balance(item[])

        # # order
        # for item in self._executor[]._order_subscriptions:
        #     ws.subscribe_order(item[][0], item[][1])

        # # my trade
        # for item in self._executor[]._my_trade_subscriptions:
        #     ws.subscribe_my_trades(item[][0], item[][1])

        # Subscribe to order data
        # var params2 = Dict[String, Any]()
        # ws.subscribe_order("BTC_USDT", params2)  # Subscribe to BTC/USDT order

        ws.connect(rt)

    fn get_on_ticker(mut self) -> OnTickerC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, ticker: Ticker):
            ptr[].__on_ticker(trading_context, ticker)

        return wrapper

    fn get_on_tickers(self) -> OnTickersC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, tickers: List[Ticker]):
            ptr[].__on_tickers(trading_context, tickers)

        return wrapper

    fn get_on_order_book(self) -> OnOrderBookC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, order_book: OrderBook):
            ptr[].__on_order_book(trading_context, order_book)

        return wrapper

    fn get_on_trade(self) -> OnTradeC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, trade: Trade):
            ptr[].__on_trade(trading_context, trade)

        return wrapper

    fn get_on_balance(self) -> OnBalanceC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, balance: Balance):
            ptr[].__on_balance(trading_context, balance)

        return wrapper

    fn get_on_order(self) -> OnOrderC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, order: Order):
            ptr[].__on_order(trading_context, order)

        return wrapper

    fn get_on_my_trade(self) -> OnMyTradeC:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper(trading_context: TradingContext, trade: Trade):
            ptr[].__on_my_trade(trading_context, trade)

        return wrapper

    fn set_on_ticker(self, on_ticker: OnTickerC) -> None:
        self._on_ticker_c.init_pointee_copy(on_ticker)

    fn set_on_tickers(self, on_tickers: OnTickersC) -> None:
        self._on_tickers_c.init_pointee_copy(on_tickers)

    fn set_on_order_book(self, on_order_book: OnOrderBookC) -> None:
        self._on_order_book_c.init_pointee_copy(on_order_book)

    fn set_on_trade(self, on_trade: OnTradeC) -> None:
        self._on_trade_c.init_pointee_copy(on_trade)

    fn set_on_balance(self, on_balance: OnBalanceC) -> None:
        self._on_balance_c.init_pointee_copy(on_balance)

    fn set_on_order(self, on_order: OnOrderC) -> None:
        self._on_order_c.init_pointee_copy(on_order)

    fn set_on_my_trade(self, on_my_trade: OnMyTradeC) -> None:
        self._on_my_trade_c.init_pointee_copy(on_my_trade)

    fn __on_ticker(
        mut self, trading_context: TradingContext, ticker: Ticker
    ) -> None:
        logi("on_ticker: " + str(trading_context) + " " + str(ticker))

    fn __on_tickers(
        mut self, trading_context: TradingContext, tickers: List[Ticker]
    ) -> None:
        logi("on_tickers: " + str(trading_context) + " " + str(len(tickers)))

    fn __on_order_book(
        mut self, trading_context: TradingContext, order_book: OrderBook
    ) -> None:
        logi("on_order_book: " + str(trading_context) + " " + str(order_book))

    fn __on_trade(
        mut self, trading_context: TradingContext, trade: Trade
    ) -> None:
        logi("on_trade: " + str(trading_context) + " " + str(trade))

    fn __on_balance(
        mut self, trading_context: TradingContext, balance: Balance
    ) -> None:
        logi("on_balance: " + str(trading_context) + " " + str(balance))

    fn __on_order(
        mut self, trading_context: TradingContext, order: Order
    ) -> None:
        logi("on_order: " + str(trading_context) + " " + str(order))

    fn __on_my_trade(
        mut self, trading_context: TradingContext, trade: Trade
    ) -> None:
        logi("on_my_trade: " + str(trading_context) + " " + str(trade))

    fn init(mut self) raises:
        self._strategy[].on_init()

        # var ot = self.get_on_ticker()
        # self._on_ticker_c.init_pointee_copy(ot)
        # var ot2 = self.get_on_tickers()
        # self._on_tickers_c.init_pointee_copy(ot2)
        # var ob = self.get_on_order_book()
        # self._on_order_book_c.init_pointee_copy(ob)
        # var t = self.get_on_trade()
        # self._on_trade_c.init_pointee_copy(t)
        # var b = self.get_on_balance()
        # self._on_balance_c.init_pointee_copy(b)
        # var o = self.get_on_order()
        # self._on_order_c.init_pointee_copy(o)
        # var mt = self.get_on_my_trade()
        # self._on_my_trade_c.init_pointee_copy(mt)

        self._running = True

    fn stop(self) raises:
        pass


fn engine_get_on_ticker[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnTickerC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, ticker: Ticker) -> None:
        ptr[].__on_ticker(trading_context, ticker)

    return wrapper


fn engine_get_on_tickers[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnTickersC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, tickers: List[Ticker]) -> None:
        ptr[].__on_tickers(trading_context, tickers)

    return wrapper


fn engine_get_on_order_book[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnOrderBookC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, order_book: OrderBook) -> None:
        ptr[].__on_order_book(trading_context, order_book)

    return wrapper


fn engine_get_on_trade[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnTradeC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, trade: Trade) -> None:
        ptr[].__on_trade(trading_context, trade)

    return wrapper


fn engine_get_on_balance[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnBalanceC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, balance: Balance) -> None:
        ptr[].__on_balance(trading_context, balance)

    return wrapper


fn engine_get_on_order[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnOrderC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, order: Order) -> None:
        ptr[].__on_order(trading_context, order)

    return wrapper


fn engine_get_on_my_trade[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) -> OnMyTradeC:
    var ptr = UnsafePointer.address_of(engine)

    fn wrapper(trading_context: TradingContext, trade: Trade) -> None:
        ptr[].__on_my_trade(trading_context, trade)

    return wrapper


fn run_engine[
    T: Exchangeable, W: ProExchangeable, S: Strategizable
](mut engine: Engine[T, W, S]) raises:
    run_async_trading_thread()

    # var ot = get_on_ticker(engine)
    # engine._on_ticker_c.init_pointee_move(ot)

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
