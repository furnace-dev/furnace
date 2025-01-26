from memory import UnsafePointer
from collections import Dict
from monoio_connect import (
    Fixed,
)
from ccxt.base.types import (
    Any,
    OrderType,
    OrderSide,
    Market,
    Currency,
    Ticker,
    OrderBook,
    Trade,
    Balances,
    Order,
    Strings,
    IntOpt,
    Str,
)
from ccxt.base import Exchangeable


trait Executable:
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

    fn fetch_ticker(self, symbol: String) raises -> Ticker:
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


struct Executor[T: Exchangeable](Executable):
    var _exchange: UnsafePointer[T]

    fn __init__(out self, exchange: UnsafePointer[T]):
        self._exchange = exchange

    fn load_markets(self, mut params: Dict[String, Any]) raises -> List[Market]:
        return self._exchange[].load_markets(params)

    fn fetch_markets(
        self, mut params: Dict[String, Any]
    ) raises -> List[Market]:
        return self._exchange[].fetch_markets(params)

    fn fetch_currencies(
        self, mut params: Dict[String, Any]
    ) raises -> List[Currency]:
        return self._exchange[].fetch_currencies(params)

    fn fetch_ticker(self, symbol: String) raises -> Ticker:
        return self._exchange[].fetch_ticker(symbol)

    fn fetch_tickers(
        self, symbols: Strings, mut params: Dict[String, Any]
    ) raises -> List[Ticker]:
        return self._exchange[].fetch_tickers(symbols, params)

    fn fetch_order_book(
        self,
        symbol: String,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> OrderBook:
        return self._exchange[].fetch_order_book(symbol, limit, params)

    fn fetch_trades(
        self,
        symbol: String,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        return self._exchange[].fetch_trades(symbol, since, limit, params)

    fn fetch_balance(self, mut params: Dict[String, Any]) raises -> Balances:
        return self._exchange[].fetch_balance(params)

    fn create_order(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> Order:
        return self._exchange[].create_order(
            symbol, type, side, amount, price, params
        )

    fn cancel_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        return self._exchange[].cancel_order(id, symbol, params)

    fn fetch_order(
        self, id: String, symbol: Str, mut params: Dict[String, Any]
    ) raises -> Order:
        return self._exchange[].fetch_order(id, symbol, params)

    fn fetch_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        return self._exchange[].fetch_orders(symbol, since, limit, params)

    fn fetch_open_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        return self._exchange[].fetch_open_orders(symbol, since, limit, params)

    fn fetch_closed_orders(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Order]:
        return self._exchange[].fetch_closed_orders(
            symbol, since, limit, params
        )

    fn fetch_my_trades(
        self,
        symbol: Str,
        since: IntOpt,
        limit: IntOpt,
        mut params: Dict[String, Any],
    ) raises -> List[Trade]:
        return self._exchange[].fetch_my_trades(symbol, since, limit, params)

    fn create_order_async(
        self,
        symbol: String,
        type: OrderType,
        side: OrderSide,
        amount: Fixed,
        price: Fixed,
        mut params: Dict[String, Any],
    ) raises -> None:
        self._exchange[].create_order_async(
            symbol, type, side, amount, price, params
        )

    fn cancel_order_async(
        self, id: String, symbol: String, mut params: Dict[String, Any]
    ) raises -> None:
        self._exchange[].cancel_order_async(id, symbol, params)
