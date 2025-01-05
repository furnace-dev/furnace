@value
@register_passable("trivial")
struct OrderSide(Stringable):
    var _value: Int8

    alias Buy = OrderSide(0)
    alias Sell = OrderSide(1)
    alias OpenLong = OrderSide(2)
    alias OpenShort = OrderSide(3)
    alias CloseLong = OrderSide(4)
    alias CloseShort = OrderSide(5)

    fn __eq__(self, other: OrderSide) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == OrderSide.Buy:
            return "Buy"
        elif self == OrderSide.Sell:
            return "Sell"
        elif self == OrderSide.OpenLong:
            return "OpenLong"
        elif self == OrderSide.OpenShort:
            return "OpenShort"
        elif self == OrderSide.CloseLong:
            return "CloseLong"
        elif self == OrderSide.CloseShort:
            return "CloseShort"
        else:
            return "Unknown"


@value
@register_passable("trivial")
struct OrderType(Stringable):
    var _value: Int8

    alias Market = OrderType(0)
    alias Limit = OrderType(1)
    alias Stop = OrderType(2)
    alias StopLimit = OrderType(3)

    fn __eq__(self, other: OrderType) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == OrderType.Market:
            return "Market"
        elif self == OrderType.Limit:
            return "Limit"
        elif self == OrderType.Stop:
            return "Stop"
        elif self == OrderType.StopLimit:
            return "StopLimit"
        else:
            return "Unknown"


@value
@register_passable("trivial")
struct OrderStatus(Stringable):
    var _value: Int8

    alias New = OrderStatus(0)
    alias Pending = OrderStatus(1)
    alias Finished = OrderStatus(2)
    alias Cancelled = OrderStatus(3)
    alias Rejected = OrderStatus(4)

    fn is_finished(self) -> Bool:
        return (
            self == OrderStatus.Finished
            or self == OrderStatus.Cancelled
            or self == OrderStatus.Rejected
        )

    fn __eq__(self, other: OrderStatus) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == OrderStatus.New:
            return "New"
        elif self == OrderStatus.Pending:
            return "Pending"
        elif self == OrderStatus.Finished:
            return "Finished"
        elif self == OrderStatus.Cancelled:
            return "Cancelled"
        elif self == OrderStatus.Rejected:
            return "Rejected"
        else:
            return "Unknown"


@value
struct Order:
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    var symbol: FixedString24
    var symbol_api: FixedString24
    var id: FixedString24
    var client_id: FixedString24
    var order_type: OrderType
    var order_side: OrderSide
    var order_status: OrderStatus
    var price: Float64
    var quantity: Float64
    var filled: Float64
    var filled_price: Float64
    var base_fee: Float64
    var quote_fee: Float64
    var plat_coin_fee: Float64  # 平台币手续费，和base quote都不匹配的时候就认为是平台币手续费
    # Todo:到底需要哪些时间戳呢
    var create_time: Int64
    var request_time: Int64
    var remote_time: Int64
    var resp_time: Int64
