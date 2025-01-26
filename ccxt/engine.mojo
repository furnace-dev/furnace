import time
from memory import UnsafePointer
from collections import Dict
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
    var ptr = context.bitcast[EnginePrivateWSRun]()
    ptr[]()
    return 0


fn _async_pub_ws_backend_task(context: UnsafePointer[UInt8]) -> UInt8:
    logi("_async_pub_ws_backend_task")
    var rt = create_monoio_runtime()
    var ptr = context.bitcast[EnginePublicWSRun]()
    ptr[]()
    return 0


struct Engine[T: Exchangeable, W: ProExchangeable, S: Strategizable]:
    var _rt: MonoioRuntimePtr
    var _exchange: UnsafePointer[T]
    var _private_ws: UnsafePointer[W]
    var _public_ws: UnsafePointer[W]
    var _strategy: UnsafePointer[S]

    fn __init__(
        out self,
        config: Dict[String, Any],
        exchange_id: ExchangeId,
        account_id: String,
        trader_id: String,
    ):
        self._rt = create_monoio_runtime()
        self._exchange = UnsafePointer[T].alloc(1)
        var trading_context = TradingContext(
            exchange_id=exchange_id, account_id=account_id, trader_id=trader_id
        )
        initialize_exchange_instance(
            self._exchange, config, trading_context, self._rt
        )
        self._private_ws = UnsafePointer[W].alloc(1)
        self._public_ws = UnsafePointer[W].alloc(1)
        initialize_pro_exchange_instance(
            self._private_ws, config, trading_context
        )
        initialize_pro_exchange_instance(
            self._public_ws, config, trading_context
        )
        self._strategy = UnsafePointer[S].alloc(1)
        __get_address_as_uninit_lvalue(self._strategy.address) = S()
        var executor = UnsafePointer[Executor[T]].alloc(1)
        __get_address_as_uninit_lvalue(executor.address) = Executor(
            self._exchange
        )
        self._strategy[].setup(executor)

    fn get_private_ws_run(self) -> EnginePrivateWSRun:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper():
            try:
                ptr[].__on_private_ws_run()
            except e:
                logw("__on_private_ws_run error: " + str(e))

        return wrapper

    fn get_public_ws_run(self) -> EnginePublicWSRun:
        var ptr = UnsafePointer.address_of(self)

        fn wrapper():
            try:
                ptr[].__on_public_ws_run()
            except e:
                logw("__on_public_ws_run error: " + str(e))

        return wrapper

    fn __on_private_ws_run(mut self) raises:
        logd("__on_private_ws_run")

    fn __on_public_ws_run(mut self) raises:
        logd("__on_public_ws_run")

    fn start(self) raises:
        run_async_trading_thread()

        self._strategy[].on_init()

        var private_context = UnsafePointer[UInt8]()
        var private_ws_run = self.get_private_ws_run()
        var private_ws_run_ptr = UnsafePointer.address_of(private_ws_run)
        private_context = private_ws_run_ptr.bitcast[UInt8]()
        var pri_tid = start_thread(_async_pri_ws_backend_task, private_context)
        logi("tid: " + str(pri_tid))

        var public_context = UnsafePointer[UInt8]()
        var public_ws_run = self.get_public_ws_run()
        var public_ws_run_ptr = UnsafePointer.address_of(public_ws_run)
        public_context = public_ws_run_ptr.bitcast[UInt8]()
        var pub_tid = start_thread(_async_pub_ws_backend_task, public_context)
        logi("tid: " + str(pub_tid))

        while True:
            sleep_ms(self._rt, 1000)

    fn stop(self) raises:
        pass
