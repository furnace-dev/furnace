@value
@register_passable("trivial")
struct TradeSide(Stringable):
    var _value: Int8

    alias Buy = TradeSide(0)
    alias Sell = TradeSide(1)

    fn __eq__(self, other: TradeSide) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self._value == 0:
            return "Buy"
        elif self._value == 1:
            return "Sell"
        else:
            return "Unknown"


@value
struct Trade(Stringable):
    var symbol: String
    var symbol_api: String
    var price: Float64
    var quantity: Float64
    var side: TradeSide
    var remote_time: Int64
    var local_time: Int64
    var update_id: Int64

    fn __str__(self) -> String:
        return String.write(
            " symbol: ",
            self.symbol,
            " price: ",
            self.price,
            " quantity: ",
            self.quantity,
            " side: ",
            String(self.side),
            " remote_time: ",
            self.remote_time,
            " local_time: ",
            self.local_time,
            " update_id: ",
            self.update_id,
        )
