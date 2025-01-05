@value
@register_passable("trivial")
struct MarketType(Stringable):
    var _value: Int8

    alias Spot = MarketType(0)
    alias UsdtSwap = MarketType(1)
    alias CoinSwap = MarketType(2)
    alias UsdtDelivery = MarketType(3)
    alias CoinDelivery = MarketType(4)

    fn __eq__(self, other: MarketType) -> Bool:
        return self._value == other._value

    fn is_spot(self) -> Bool:
        return self == MarketType.Spot

    fn is_swap(self) -> Bool:
        return self == MarketType.UsdtSwap or self == MarketType.CoinSwap

    fn is_delivery(self) -> Bool:
        return (
            self == MarketType.UsdtDelivery or self == MarketType.CoinDelivery
        )

    fn __str__(self) -> String:
        if self == MarketType.Spot:
            return "spot"
        elif self == MarketType.UsdtSwap:
            return "usdt.swap"
        elif self == MarketType.CoinSwap:
            return "coin.swap"
        elif self == MarketType.UsdtDelivery:
            return "usdt.delivery"
        elif self == MarketType.CoinDelivery:
            return "coin.delivery"
        else:
            return "UNKNOWN"
