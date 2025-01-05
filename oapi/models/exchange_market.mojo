from monoio_connect import nanoid


@value
@register_passable("trivial")
struct ExchangeMarket(Stringable):
    var exchange: Exchange
    var market_type: MarketType

    fn new_client_id(self) -> String:
        return nanoid()

    fn to_string(self) -> String:
        return String.write(str(self.exchange), ".", str(self.market_type))

    fn int64(self) -> Int64:
        return Int64(
            int(self.exchange._value) << 16 + int(self.market_type._value)
        )

    fn int32(self) -> Int32:
        return Int32(
            int(self.exchange._value) << 16 + int(self.market_type._value)
        )

    fn __str__(self) -> String:
        return str(self.exchange) + "." + str(self.market_type)
