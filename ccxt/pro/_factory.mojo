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
from ccxt.base.pro_exchangeable import ProExchangeable


fn create_pro_exchange_instance[
    T: ProExchangeable
](config: Dict[String, Any], trading_context: TradingContext,) -> T:
    return T(config, trading_context)


fn initialize_pro_exchange_instance[
    T: ProExchangeable
](
    mut exchange_pointer: UnsafePointer[T],
    config: Dict[String, Any],
    trading_context: TradingContext,
):
    if exchange_pointer == UnsafePointer[T]():
        exchange_pointer = UnsafePointer[T].alloc(1)
    __get_address_as_uninit_lvalue(exchange_pointer.address) = T(
        config, trading_context
    )
