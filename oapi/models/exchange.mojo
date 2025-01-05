@value
@register_passable("trivial")
struct Exchange(Stringable):
    var _value: Int8

    alias Binance = Exchange(0)
    alias Bitget = Exchange(1)
    alias Bybit = Exchange(2)
    alias OKX = Exchange(3)
    alias Bitmex = Exchange(4)
    alias Gateio = Exchange(5)

    @staticmethod
    fn parse(value: String) raises -> Exchange:
        if value == "binance":
            return Exchange.Binance
        elif value == "bitget":
            return Exchange.Bitget
        elif value == "bybit":
            return Exchange.Bybit
        elif value == "okx":
            return Exchange.OKX
        elif value == "bitmex":
            return Exchange.Bitmex
        elif value == "gateio":
            return Exchange.Gateio
        else:
            raise Error(String.write("Unknown exchange: ", value))

    fn __eq__(self, other: Exchange) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == Exchange.Binance:
            return "binance"
        elif self == Exchange.Bitget:
            return "bitget"
        elif self == Exchange.Bybit:
            return "bybit"
        elif self == Exchange.OKX:
            return "okx"
        elif self == Exchange.Bitmex:
            return "bitmex"
        elif self == Exchange.Gateio:
            return "gateio"
        else:
            return "UNKNOWN"
