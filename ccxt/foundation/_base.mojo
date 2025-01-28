from collections import List
from ccxt.base.types import (
    TradingContext,
    Ticker,
    OrderBook,
    Trade,
    Balance,
    Order,
)


fn empty_on_ticker(trading_context: TradingContext, ticker: Ticker) -> None:
    pass


fn empty_on_tickers(
    trading_context: TradingContext, tickers: List[Ticker]
) -> None:
    pass


fn empty_on_order_book(
    trading_context: TradingContext, order_book: OrderBook
) -> None:
    pass


fn empty_on_trade(trading_context: TradingContext, trade: Trade) -> None:
    pass


fn empty_on_balance(trading_context: TradingContext, balance: Balance) -> None:
    pass


fn empty_on_order(trading_context: TradingContext, order: Order) -> None:
    pass


fn empty_on_my_trade(trading_context: TradingContext, trade: Trade) -> None:
    pass