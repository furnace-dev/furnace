@value
@register_passable("trivial")
struct SubOperationType(Stringable):
    var _value: Int8

    alias TickerSub = SubOperationType(0)
    alias TickerSubAll = SubOperationType(1)
    alias OrderbookSub = SubOperationType(2)
    alias TradeSub = SubOperationType(3)
    alias TickerUnsub = SubOperationType(4)
    alias OrderbookUnsub = SubOperationType(5)
    alias TradeUnsub = SubOperationType(6)

    fn __eq__(self, other: SubOperationType) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == SubOperationType.TickerSub:
            return "ticker_sub"
        elif self == SubOperationType.TickerSubAll:
            return "ticker_sub_all"
        elif self == SubOperationType.OrderbookSub:
            return "orderbook_sub"
        elif self == SubOperationType.TradeSub:
            return "trade_sub"
        elif self == SubOperationType.TickerUnsub:
            return "ticker_unsub"
        elif self == SubOperationType.OrderbookUnsub:
            return "orderbook_unsub"
        elif self == SubOperationType.TradeUnsub:
            return "trade_unsub"
        else:
            return "Unknown"