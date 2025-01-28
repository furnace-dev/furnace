from memory import UnsafePointer
from monoio_connect import (
    Fixed,
    MonoioRuntimePtr,
)
from ccxt.base.types import (
    ExchangeId,
    Market,
    Currency,
    Ticker,
    OrderBook,
    Trade,
    Order,
    Balances,
)


trait Exchangeable(Movable):
    """
    Exchangeable trait, which is implemented by all exchanges.

    Exchanges implementing this trait are required to provide some
    basic methods for interacting with the exchange.
    """

    fn __init__(
        out self,
        config: Dict[String, Any],
        trading_context: TradingContext,
        rt: MonoioRuntimePtr,
    ):
        ...

    fn id(self) -> ExchangeId:
        ...

    fn load_markets(self, mut params: Dict[String, Any]) raises -> List[Market]:
        ...

    fn fetch_markets(
        self, mut params: Dict[String, Any]
    ) raises -> List[Market]:
        ...

    fn fetch_currencies(
        self, mut params: Dict[String, Any]
    ) raises -> List[Currency]:
        ...

    fn fetch_ticker(self: Self, symbol: String) raises -> Ticker:
        ...

    fn fetch_tickers(
        self, symbols: Strings, mut params: Dict[String, Any]
    ) raises -> List[Ticker]:
        ...

    fn fetch_order_book(
        self,
        symbol: String,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> OrderBook:
        ...

    # fn fetch_ohlcv(self: Self, symbol: String, timeframe: String, since: Int, limit: Int) -> List[OHLCV]:
    #     ...

    # fn fetch_status(self: Self) -> Status:
    #     ...

    fn fetch_trades(
        self,
        symbol: String,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        ...

    fn fetch_balance(self, mut params: Dict[String, Any]) raises -> Balances:
        ...

    fn create_order(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> Order:
        ...

    fn cancel_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        ...

    fn fetch_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        ...

    fn fetch_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        ...

    fn fetch_open_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        ...

    fn fetch_closed_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        ...

    fn fetch_my_trades(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        ...

    # fn deposit(self: Self, currency: String, amount: Float64) -> Bool:
    #     ...

    # fn withdraw(self: Self, currency: String, amount: Float64) -> Bool:
    #     ...

    fn create_order_async(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> None:
        ...

    fn cancel_order_async(
        self, id: String, symbol: String, mut params: Dict[String, Any]
    ) raises -> None:
        ...

    fn set_on_order(mut self: Self, owned on_order: OnOrderC) -> None:
        ...

    fn on_order(self, order: Order) -> None:
        ...
