from collections import List


@value
@register_passable("trivial")
struct OrderbookEntry:
    var price: Float64
    var size: Float64


@value
struct Orderbook:
    """
    订单簿.
    """

    var exchange: Exchange
    var symbol: String
    var asks: List[OrderbookEntry]
    var bids: List[OrderbookEntry]
    var remote_time: Int64
    var local_time: Int64
    var update_id: Int64
