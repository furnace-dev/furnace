from .suboperation_type import SubOperationType


@value
struct SubOperation:
    var symbol: String
    var symbol_api: String
    var type: SubOperationType

    fn is_sub(self) -> Bool:
        return (
            self.type == SubOperationType.TickerSub
            or self.type == SubOperationType.OrderbookSub
            or self.type == SubOperationType.TradeSub
            or self.type == SubOperationType.TickerSubAll
        )
