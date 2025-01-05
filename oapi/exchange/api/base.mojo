from collections import List
from oapi.models import *
from .ex_config import ExConfig


struct Callbacks:
    # var on_event: fn(notify: EventNotify)
    # var on_pair: fn(pair: List[Pair])
    # var on_order: fn(order: Order)
    # var on_ticker: fn(ticker: Ticker)
    # var on_trade: fn(trade: Trade)
    var on_orderbook: fn (orderbook: Orderbook) -> None
    # var on_spot_position: fn(spot: SpotPosition)
    # var on_future_position: fn(future: FuturePosition)
    # var on_spot_positions: fn(spot: List[SpotPosition])
    # var on_future_positions: fn(future: List[FuturePosition])
    # var on_error: fn(err: QuantError)
