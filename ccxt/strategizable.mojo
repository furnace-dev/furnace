from memory import UnsafePointer
from ccxt.base import (
    Ticker,
    OrderBook,
    Trade,
    Balance,
    Order,
    Trade,
    Exchangeable,
)
from .executor import Executable


trait Strategizable:
    fn __init__(out self):
        ...

    fn setup[E: Executable](mut self, ex: UnsafePointer[E]):
        ...

    fn on_init(mut self) raises:
        ...

    fn on_deinit(mut self) raises:
        ...

    fn on_ticker(mut self, ticker: Ticker) raises:
        ...

    fn on_order_book(mut self, order_book: OrderBook) raises:
        ...

    fn on_trade(mut self, trade: Trade) raises:
        ...

    fn on_balance(mut self, balance: Balance) raises:
        ...

    fn on_order(mut self, order: Order) raises:
        ...

    fn on_my_trade(mut self, trade: Trade) raises:
        ...
