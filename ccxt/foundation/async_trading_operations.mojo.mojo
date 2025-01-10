from memory import UnsafePointer
from ccxt.base.types import *
from ._common_utils import *
from .bitmex import BitMEX
from .bybit import Bybit
from .gate import Gate
from monoio_connect import *


@always_inline
fn _create_order_internal[
    T: Exchangeable
](request: UnsafePointer[AsyncTradingRequest]) raises:
    var exchange = request[].bitcast[T]()
    var req = request[].data[SubmitOrderData]
    var symbol = req.symbol
    var order_type = req.order_type
    var order_side = req.order_side
    var amount = req.amount
    var price = req.price
    var params = Dict[String, Any]()
    var order = exchange[].create_order(
        symbol,
        order_type,
        order_side,
        amount,
        price,
        params,
    )
    logt("order: " + str(order))
    # trigger callback
    exchange[].on_order(order)


@always_inline
fn _create_order(request: UnsafePointer[AsyncTradingRequest]) raises:
    var exchange_id = request[].exchange_id
    if exchange_id == ExchangeId.Gateio:
        _create_order_internal[Gate](request)
    elif exchange_id == ExchangeId.Bybit:
        _create_order_internal[Bybit](request)
    elif exchange_id == ExchangeId.Bitmex:
        _create_order_internal[BitMEX](request)
    else:
        logw("unknown exchange_id: " + str(exchange_id))


@always_inline
fn _cancel_order_internal[
    T: Exchangeable
](request: UnsafePointer[AsyncTradingRequest]) raises:
    var exchange = request[].bitcast[T]()
    var req = request[].data[SubmitCancelOrderData]
    var symbol = req.symbol
    var order_id = req.order_id
    exchange[].cancel_order(symbol, order_id)


@allways_inline
fn _cancel_order(request: UnsafePointer[AsyncTradingRequest]) raises:
    var exchange_id = request[].exchange_id
    if exchange_id == ExchangeId.Gateio:
        _cancel_order_internal[Gate](request)
    elif exchange_id == ExchangeId.Bybit:
        _cancel_order_internal[Bybit](request)
    elif exchange_id == ExchangeId.Bitmex:
        _cancel_order_internal[BitMEX](request)
    else:
        logw("unknown exchange_id: " + str(exchange_id))


fn _async_trading_backend() raises -> None:
    """
    The entry point of the asynchronous trading thread
    """

    # set cpu affinity
    # bind_to_cpu_set(0)

    var rt = create_monoio_runtime()

    while True:
        var request = async_trading_channel_ptr()[].recv[AsyncTradingRequest]()
        if not request:
            sleep(rt, 1000)
            continue
        # logt("Received request")
        var request_ = request.value()
        if request_[].type == 0:
            # logt("Create order")
            _create_order(request_)
        elif request_[].type == 1:
            # logt("Cancel order")
            _cancel_order(request_)
        request_.destroy_pointee()
        request_.free()


fn run_async_trading_thread() raises:
    """
    Start the asynchronous trading thread
    """
    var tid = start_thread(_async_trading_backend)
    logd("tid: " + str(tid))
