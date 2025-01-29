from memory import UnsafePointer
from collections import Dict
from monoio_connect import (
    logd,
    logi,
    logw,
    loge,
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
    Balance,
    Balances,
    Order,
    Strings,
    IntOpt,
    Str,
    OnTickerC,
    OnTickersC,
    OnOrderBookC,
    OnTradeC,
    OnBalanceC,
    OnOrderC,
    OnMyTradeC,
    TradingContext,
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


struct Executor[T: Exchangeable](Executable):
    var _exchange: UnsafePointer[T]
    var _ticker_subscriptions: List[Tuple[String, Dict[String, Any]]]
    var _tickers_subscriptions: List[Tuple[Strings, Dict[String, Any]]]
    var _order_book_subscriptions: List[Tuple[String, Dict[String, Any]]]
    var _trade_subscriptions: List[Tuple[String, Dict[String, Any]]]
    var _balance_subscriptions: List[Dict[String, Any]]
    var _order_subscriptions: List[Tuple[String, Dict[String, Any]]]
    var _my_trade_subscriptions: List[Tuple[String, Dict[String, Any]]]

    fn __init__(out self, exchange: UnsafePointer[T]):
        self._exchange = exchange
        self._ticker_subscriptions = List[Tuple[String, Dict[String, Any]]]()
        self._tickers_subscriptions = List[Tuple[Strings, Dict[String, Any]]]()
        self._order_book_subscriptions = List[
            Tuple[String, Dict[String, Any]]
        ]()
        self._trade_subscriptions = List[Tuple[String, Dict[String, Any]]]()
        self._balance_subscriptions = List[Dict[String, Any]]()
        self._order_subscriptions = List[Tuple[String, Dict[String, Any]]]()
        self._my_trade_subscriptions = List[Tuple[String, Dict[String, Any]]]()

    fn __del__(owned self):
        pass

    fn on_ticker(
        mut self, trading_context: TradingContext, ticker: Ticker
    ) -> None:
        logd("on_ticker")
        # self._strategy[].on_ticker(ticker)

    fn on_tickers(
        mut self, trading_context: TradingContext, tickers: List[Ticker]
    ) -> None:
        logd("on_tickers")
        # self._strategy[].on_tickers(tickers)

    fn on_order_book(
        mut self, trading_context: TradingContext, order_book: OrderBook
    ) -> None:
        logd("on_order_book")
        # self._strategy[].on_order_book(order_book)

    fn on_trade(
        mut self, trading_context: TradingContext, trade: Trade
    ) -> None:
        logd("on_trade")
        # self._strategy[].on_trade(trade)

    fn on_balance(
        mut self, trading_context: TradingContext, balance: Balance
    ) -> None:
        logd("on_balance")
        # self._strategy[].on_balance(balance)

    fn on_order(
        mut self, trading_context: TradingContext, order: Order
    ) -> None:
        logd("on_order")
        # self._strategy[].on_order(order)

    fn on_my_trade(
        mut self, trading_context: TradingContext, trade: Trade
    ) -> None:
        logd("on_my_trade")
        # self._strategy[].on_my_trade(trade)

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

    fn subscribe_ticker(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        self._ticker_subscriptions.append((symbol, params))

    fn subscribe_tickers(
        mut self, symbols: Strings, params: Dict[String, Any]
    ) raises -> None:
        self._tickers_subscriptions.append((symbols, params))

    fn subscribe_order_book(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        self._order_book_subscriptions.append((symbol, params))

    fn subscribe_trade(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        self._trade_subscriptions.append((symbol, params))

    fn subscribe_balance(mut self, params: Dict[String, Any]) raises -> None:
        self._balance_subscriptions.append(params)

    fn subscribe_order(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        self._order_subscriptions.append((symbol, params))

    fn subscribe_my_trades(
        mut self, symbol: String, params: Dict[String, Any]
    ) raises -> None:
        self._my_trade_subscriptions.append((symbol, params))
