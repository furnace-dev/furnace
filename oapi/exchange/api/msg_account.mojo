from oapi.models import *


@value
struct GetAccountRequest:
    var exchange_market: ExchangeMarket
    var account_id: UInt64


@value
struct SetCrossRequest:
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    var symbol_api: FixedString24
    var cross: Bool


@value
struct SetLeverageRequest:
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    var symbol_api: FixedString24
    var leverage: Float64


@value
struct SetPositionSideRequest:
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    var dul_side: Bool  # True: 双向持仓


@value
struct SetMultiMarginRequest:
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    var multi: Bool
