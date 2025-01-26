from memory import UnsafePointer
from collections import Dict
from monoio_connect import (
    MonoioRuntimePtr,
)
from ccxt.base import (
    ExchangeId,
    TradingContext,
    Any,
)
from ccxt.base.exchangeable import Exchangeable
from ccxt.foundation.bybit import Bybit
from ccxt.foundation.gate import Gate
from ccxt.foundation.binance import Binance
from ccxt.foundation.bitmex import BitMEX


fn create_exchange_instance[
    T: Exchangeable
](
    config: Dict[String, Any],
    trading_context: TradingContext,
    rt: MonoioRuntimePtr,
) -> T:
    return T(config, trading_context, rt)


fn initialize_exchange_instance[
    T: Exchangeable
](
    mut exchange_pointer: UnsafePointer[T],
    config: Dict[String, Any],
    trading_context: TradingContext,
    rt: MonoioRuntimePtr,
):
    if exchange_pointer == UnsafePointer[T]():
        exchange_pointer = UnsafePointer[T].alloc(1)
    __get_address_as_uninit_lvalue(exchange_pointer.address) = T(
        config, trading_context, rt
    )


# fn create_exchange_instance[
#     T: Exchangeable
# ](
#     config: Dict[String, Any],
#     exchange_id: ExchangeId,
#     account_id: String,
#     trader_id: String,
#     rt: MonoioRuntimePtr,
# ) raises -> T:
#     var trading_context = TradingContext(
#         exchange_id=exchange_id, account_id=account_id, trader_id=trader_id
#     )
#     if exchange_id == ExchangeId.bybit:
#         return create_exchange_instance[Bybit](config, trading_context, rt)
#     elif exchange_id == ExchangeId.binance:
#         return create_exchange_instance[Binance](config, trading_context, rt)
#     elif exchange_id == ExchangeId.bitmex:
#         return create_exchange_instance[BitMEX](config, trading_context, rt)
#     elif exchange_id == ExchangeId.gateio:
#         return create_exchange_instance[Gate](config, trading_context, rt)
#     else:
#         raise Error("not found")
