from memory import UnsafePointer
from monoio_connect import MonoioRuntimePtr
from .types import (
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


trait ProExchangeable(Movable):
    """
    ProExchangeable trait, which is implemented by all exchanges.
    """

    fn __init__(
        out self, config: Dict[String, Any], trading_context: TradingContext
    ):
        ...

    fn set_on_ticker(self, on_ticker: OnTickerC) -> None:
        ...

    fn set_on_tickers(self, on_tickers: OnTickersC) -> None:
        ...

    fn set_on_order_book(
        self, on_order_book: OnOrderBookC
    ) -> None:
        ...

    fn set_on_trade(self, on_trade: OnTradeC) -> None:
        ...

    fn set_on_balance(self, on_balance: OnBalanceC) -> None:
        ...

    fn set_on_order(self, on_order: OnOrderC) -> None:
        ...

    fn set_on_my_trade(self, on_my_trade: OnMyTradeC) -> None:
        ...

    fn subscribe_ticker(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        ...

    fn subscribe_tickers(
        mut self, symbols: Strings, params: Dict[String, Any]
    ) raises -> None:
        ...

    fn subscribe_order_book(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        ...

    fn subscribe_trade(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        ...

    fn subscribe_balance(mut self, params: Dict[String, Any]) raises -> None:
        ...

    fn subscribe_order(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        ...

    fn subscribe_my_trades(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        ...

    fn connect(mut self, rt: MonoioRuntimePtr) raises:
        ...


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
