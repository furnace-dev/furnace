from oapi.models import *


@value
@register_passable("trivial")
struct QuantEvent(Stringable):
    var _value: Int8

    alias MarketDisconnected = QuantEvent(0)
    alias MarketConnected = QuantEvent(1)
    alias TradeDisconnected = QuantEvent(2)
    alias TradeConnected = QuantEvent(3)

    fn __eq__(self, other: QuantEvent) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == QuantEvent.MarketDisconnected:
            return "MarketDisconnected"
        elif self == QuantEvent.MarketConnected:
            return "MarketConnected"
        elif self == QuantEvent.TradeDisconnected:
            return "TradeDisconnected"
        elif self == QuantEvent.TradeConnected:
            return "TradeConnected"
        else:
            return "Unknown"


@value
struct EventNotify(Stringable):
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    # symbol not use for raw api
    var symbol: String
    var symbol_api: String
    var event: QuantEvent

    fn __str__(self) -> String:
        if len(self.symbol) == 0 and len(self.symbol_api) == 0:
            return "ExchangeMarket: " + str(self.exchange_market) +
                ", Event: " + str(self.event) +
                ", AccountID: " + str(self.account_id)
        elif len(self.symbol) == 0:
            return "ExchangeMarket: " + str(self.exchange_market) +
                ", Event: " + str(self.event) +
                ", SymbolApi: " + self.symbol_api +
                ", AccountID: " + str(self.account_id)
        elif len(self.symbol_api) == 0:
            return "ExchangeMarket: " + str(self.exchange_market) +
                ", Event: " + str(self.event) +
                ", Symbol: " + self.symbol +
                ", AccountID: " + str(self.account_id)
        else:
            return "ExchangeMarket: " + str(self.exchange_market) +
                ", Event: " + str(self.event) +
                ", Symbol: " + self.symbol +
                ", SymbolApi: " + self.symbol_api +
                ", AccountID: " + str(self.account_id)
