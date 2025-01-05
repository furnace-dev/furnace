from collections import List
from monoio_connect import *
from oapi.models import *


@value
struct CoinAddress:
    var network: String
    var coin: String
    var address: String


@value
struct ExConfig:
    var exchange_market: ExchangeMarket
    var account_id: UInt64
    var access: String
    var secret: String
    var phrase: String
    var ban_ws_order: Bool
    var ban_cookie_order: Bool
    var sub_account: String
    var colo: Bool
    var margin: Bool
    var order_per_second: Int
    var cookie: String
    var headers: List[List[String]]

    # others
    var deposit_address: List[CoinAddress]
    var withdraw_address: List[CoinAddress]

    fn get_order_per_second(self) -> Int:
        if self.order_per_second != 0:
            return self.order_per_second

        if (
            self.exchange_market.exchange == Exchange.Binance
            or self.exchange_market.exchange == Exchange.Bitget
        ):
            return 10

        return 10

    fn update(mut self, other: ExConfig) -> None:
        self.access = other.access
        self.secret = other.secret
        self.phrase = other.phrase
        self.colo = other.colo
        var pre = self.cookie
        self.cookie = other.cookie
        logw(String.write("ExConfig.Update ", pre == self.cookie))
        self.ban_cookie_order = other.ban_cookie_order
        self.ban_ws_order = other.ban_ws_order
