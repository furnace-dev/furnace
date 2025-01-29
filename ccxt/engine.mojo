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


struct Engine[E: Exchangeable, PE: ProExchangeable, S: Strategizable](Movable):
    var _config: Dict[String, Any]
    var _trading_context: TradingContext
    var _rt: MonoioRuntimePtr
    var _exchange: UnsafePointer[E]
    var _private_ws: UnsafePointer[PE]
    var _public_ws: UnsafePointer[PE]
    var _executor: UnsafePointer[Executor[E]]
    var _strategy: UnsafePointer[S]
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
        self._exchange = UnsafePointer[E].alloc(1)
        self._trading_context = TradingContext(
            exchange_id=exchange_id, account_id=account_id, trader_id=trader_id
        )
        initialize_exchange_instance(
            self._exchange, config, self._trading_context, self._rt
        )
        self._private_ws = UnsafePointer[PE].alloc(1)
        self._public_ws = UnsafePointer[PE].alloc(1)
        initialize_pro_exchange_instance(
            self._private_ws, config, self._trading_context
        )
        initialize_pro_exchange_instance(
            self._public_ws, config, self._trading_context
        )

        self._executor = UnsafePointer[Executor[E]].alloc(1)
        __get_address_as_uninit_lvalue(self._executor.address) = Executor(
            self._exchange
        )
        self._strategy = UnsafePointer[S].alloc(1)
        __get_address_as_uninit_lvalue(self._strategy.address) = S(
            self._executor
        )
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
        self._running = existing._running

    fn __on_private_ws_run(mut self) raises:
        logd("__on_private_ws_run")
        var rt = create_monoio_runtime()
        for sub in self._executor[]._balance_subscriptions:
            logd("subscribe_balance")
            self._private_ws[].subscribe_balance(sub[])
        for sub in self._executor[]._order_subscriptions:
            logd("subscribe_order: " + sub[][0])
            self._private_ws[].subscribe_order(sub[][0], sub[][1])
        for sub in self._executor[]._my_trade_subscriptions:
            logd("subscribe_my_trade: " + sub[][0])
            self._private_ws[].subscribe_my_trades(sub[][0], sub[][1])
        self._private_ws[].connect(rt)

    fn __on_public_ws_run(mut self) raises:
        logd("__on_public_ws_run")
        var rt = create_monoio_runtime()
        for sub in self._executor[]._ticker_subscriptions:
            logd("subscribe_ticker: " + sub[][0])
            self._public_ws[].subscribe_ticker(sub[][0], sub[][1])
        for sub in self._executor[]._order_book_subscriptions:
            logd("subscribe_order_book: " + sub[][0])
            self._public_ws[].subscribe_order_book(sub[][0], sub[][1])
        for sub in self._executor[]._trade_subscriptions:
            logd("subscribe_trade: " + sub[][0])
            self._public_ws[].subscribe_trade(sub[][0], sub[][1])
        self._public_ws[].connect(rt)

    fn init(mut self) raises:
        logd("init")

        var ex_ptr = self._executor
        var s_ptr = self._strategy

        fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
            ex_ptr[].on_ticker(trading_context, ticker)
            try:
                s_ptr[].on_ticker(ticker)
            except e:
                loge("strategy on_ticker error: " + str(e))

        fn on_tickers(
            trading_context: TradingContext, tickers: List[Ticker]
        ) -> None:
            ex_ptr[].on_tickers(trading_context, tickers)
            try:
                for ticker in tickers:
                    s_ptr[].on_ticker(ticker[])
            except e:
                loge("strategy on_tickers error: " + str(e))

        fn on_order_book(
            trading_context: TradingContext, order_book: OrderBook
        ) -> None:
            ex_ptr[].on_order_book(trading_context, order_book)
            try:
                s_ptr[].on_order_book(order_book)
            except e:
                loge("strategy on_order_book error: " + str(e))

        fn on_trade(trading_context: TradingContext, trade: Trade) -> None:
            ex_ptr[].on_trade(trading_context, trade)
            try:
                s_ptr[].on_trade(trade)
            except e:
                loge("strategy on_trade error: " + str(e))

        fn on_balance(
            trading_context: TradingContext, balance: Balance
        ) -> None:
            ex_ptr[].on_balance(trading_context, balance)
            try:
                s_ptr[].on_balance(balance)
            except e:
                loge("strategy on_balance error: " + str(e))

        fn on_order(trading_context: TradingContext, order: Order) -> None:
            ex_ptr[].on_order(trading_context, order)
            try:
                s_ptr[].on_order(order)
            except e:
                loge("strategy on_order error: " + str(e))

        fn on_my_trade(trading_context: TradingContext, trade: Trade) -> None:
            ex_ptr[].on_my_trade(trading_context, trade)
            try:
                s_ptr[].on_my_trade(trade)
            except e:
                loge("strategy on_my_trade error: " + str(e))

        self._private_ws[].set_on_ticker(on_ticker)
        self._private_ws[].set_on_tickers(on_tickers)
        self._private_ws[].set_on_order_book(on_order_book)
        self._private_ws[].set_on_trade(on_trade)
        self._private_ws[].set_on_balance(on_balance)
        self._private_ws[].set_on_order(on_order)
        self._private_ws[].set_on_my_trade(on_my_trade)
        logd("private_ws set_on_ticker done")

        self._public_ws[].set_on_ticker(on_ticker)
        self._public_ws[].set_on_tickers(on_tickers)
        self._public_ws[].set_on_order_book(on_order_book)
        self._public_ws[].set_on_trade(on_trade)
        self._public_ws[].set_on_balance(on_balance)
        self._public_ws[].set_on_order(on_order)
        self._public_ws[].set_on_my_trade(on_my_trade)
        logd("public_ws set_on_ticker done")

        self._strategy[].on_init()
        logd("strategy on_init done")

        self._running = True
        logd("engine init done")

    fn start(mut self) raises:
        logd("engine start")
        run_async_trading_thread()

        try:
            self.init()
        except e:
            logw("init engine error: " + str(e))
            return

        @parameter
        fn run_loop(n: Int) -> None:
            logi("task " + str(n) + " thread id: " + str(gettid()))
            if n == 0:
                try:
                    self.__on_private_ws_run()
                except e:
                    loge("private_ws on_private_ws_run error: " + str(e))
            elif n == 1:
                try:
                    self.__on_public_ws_run()
                except e:
                    loge("public_ws on_public_ws_run error: " + str(e))

        parallelize[run_loop](2)

        try:
            self._strategy[].on_deinit()
        except e:
            loge("strategy on_deinit error: " + str(e))

        logi("engine done.")

    fn stop(self) raises:
        logd("engine stop")


fn run[
    E: Exchangeable, PE: ProExchangeable, S: Strategizable
](
    config: Dict[String, Any],
    exchange_id: ExchangeId,
    account_id: String,
    trader_id: String,
) -> None:
    var trading_context = TradingContext(
        exchange_id=exchange_id, account_id=account_id, trader_id=trader_id
    )
    var rt = create_monoio_runtime()
    var exchange_ptr = UnsafePointer[E].alloc(1)
    __get_address_as_uninit_lvalue(exchange_ptr.address) = E(
        config, trading_context, rt
    )
    var executor_ptr = UnsafePointer[Executor[E]].alloc(1)
    __get_address_as_uninit_lvalue(executor_ptr.address) = Executor[E](
        exchange_ptr
    )

    var private_ws_ptr = UnsafePointer[PE].alloc(1)
    var public_ws_ptr = UnsafePointer[PE].alloc(1)
    __get_address_as_uninit_lvalue(private_ws_ptr.address) = PE(
        config, trading_context
    )
    __get_address_as_uninit_lvalue(public_ws_ptr.address) = PE(
        config, trading_context
    )

    var strategy_ptr = UnsafePointer[S].alloc(1)
    __get_address_as_uninit_lvalue(strategy_ptr.address) = S(executor_ptr)

    fn on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
        executor_ptr[].on_ticker(trading_context, ticker)
        try:
            strategy_ptr[].on_ticker(ticker)
        except e:
            loge("strategy on_ticker error: " + str(e))

    fn on_tickers(
        trading_context: TradingContext, tickers: List[Ticker]
    ) -> None:
        executor_ptr[].on_tickers(trading_context, tickers)
        try:
            for ticker in tickers:
                strategy_ptr[].on_ticker(ticker[])
        except e:
            loge("strategy on_tickers error: " + str(e))

    fn on_order_book(
        trading_context: TradingContext, order_book: OrderBook
    ) -> None:
        executor_ptr[].on_order_book(trading_context, order_book)
        try:
            strategy_ptr[].on_order_book(order_book)
        except e:
            loge("strategy on_order_book error: " + str(e))

    fn on_trade(trading_context: TradingContext, trade: Trade) -> None:
        executor_ptr[].on_trade(trading_context, trade)
        try:
            strategy_ptr[].on_trade(trade)
        except e:
            loge("strategy on_trade error: " + str(e))

    fn on_balance(trading_context: TradingContext, balance: Balance) -> None:
        executor_ptr[].on_balance(trading_context, balance)
        try:
            strategy_ptr[].on_balance(balance)
        except e:
            loge("strategy on_balance error: " + str(e))

    fn on_order(trading_context: TradingContext, order: Order) -> None:
        executor_ptr[].on_order(trading_context, order)
        try:
            strategy_ptr[].on_order(order)
        except e:
            loge("strategy on_order error: " + str(e))

    fn on_my_trade(trading_context: TradingContext, trade: Trade) -> None:
        executor_ptr[].on_my_trade(trading_context, trade)
        try:
            strategy_ptr[].on_my_trade(trade)
        except e:
            loge("strategy on_my_trade error: " + str(e))

    private_ws_ptr[].set_on_ticker(on_ticker)
    private_ws_ptr[].set_on_tickers(on_tickers)
    private_ws_ptr[].set_on_order_book(on_order_book)
    private_ws_ptr[].set_on_trade(on_trade)
    private_ws_ptr[].set_on_balance(on_balance)
    private_ws_ptr[].set_on_order(on_order)
    private_ws_ptr[].set_on_my_trade(on_my_trade)

    public_ws_ptr[].set_on_ticker(on_ticker)
    public_ws_ptr[].set_on_tickers(on_tickers)
    public_ws_ptr[].set_on_order_book(on_order_book)
    public_ws_ptr[].set_on_trade(on_trade)
    public_ws_ptr[].set_on_balance(on_balance)
    public_ws_ptr[].set_on_order(on_order)
    public_ws_ptr[].set_on_my_trade(on_my_trade)

    try:
        strategy_ptr[].on_init()
    except e:
        loge("strategy on_init error: " + str(e))
        return

    @parameter
    fn run_loop(n: Int) -> None:
        logi("task " + str(n) + " thread id: " + str(gettid()))
        if n == 0:
            try:
                __on_private_ws_run[PE, E](private_ws_ptr, executor_ptr)
            except e:
                loge("private_ws on_private_ws_run error: " + str(e))
        elif n == 1:
            try:
                __on_public_ws_run[PE, E](public_ws_ptr, executor_ptr)
            except e:
                loge("public_ws on_public_ws_run error: " + str(e))

    parallelize[run_loop](2)

    try:
        strategy_ptr[].on_deinit()
    except e:
        loge("strategy on_deinit error: " + str(e))

    logi("engine done.")

    executor_ptr.destroy_pointee()
    executor_ptr.free()
    private_ws_ptr.destroy_pointee()
    private_ws_ptr.free()
    public_ws_ptr.destroy_pointee()
    public_ws_ptr.free()


fn __on_private_ws_run[
    PE: ProExchangeable, E: Exchangeable
](mut private_ws: UnsafePointer[PE], ex: UnsafePointer[Executor[E]]) raises:
    logd("__on_private_ws_run")
    var rt = create_monoio_runtime()
    for sub in ex[]._balance_subscriptions:
        logd("subscribe_balance")
        private_ws[].subscribe_balance(sub[])
    for sub in ex[]._order_subscriptions:
        logd("subscribe_order: " + sub[][0])
        private_ws[].subscribe_order(sub[][0], sub[][1])
    for sub in ex[]._my_trade_subscriptions:
        logd("subscribe_my_trade: " + sub[][0])
        private_ws[].subscribe_my_trades(sub[][0], sub[][1])
    private_ws[].connect(rt)


fn __on_public_ws_run[
    PE: ProExchangeable, E: Exchangeable
](mut public_ws: UnsafePointer[PE], ex: UnsafePointer[Executor[E]]) raises:
    logd("__on_public_ws_run")
    var rt = create_monoio_runtime()
    for sub in ex[]._ticker_subscriptions:
        logd("subscribe_ticker: " + sub[][0])
        public_ws[].subscribe_ticker(sub[][0], sub[][1])
    for sub in ex[]._order_book_subscriptions:
        logd("subscribe_order_book: " + sub[][0])
        public_ws[].subscribe_order_book(sub[][0], sub[][1])
    for sub in ex[]._trade_subscriptions:
        logd("subscribe_trade: " + sub[][0])
        public_ws[].subscribe_trade(sub[][0], sub[][1])
    public_ws[].connect(rt)
