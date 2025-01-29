from sys.ffi import _Global
from collections import Dict
from memory import UnsafePointer
from utils import Variant
from monoio_connect.channel import Channel
from monoio_connect import Fixed
from ccxt.base.types import OrderType, OrderSide, ExchangeId, Any
from ccxt.base.exchangeable import Exchangeable


@value
struct CreateOrderRequestData:
    var symbol: String
    var order_type: OrderType
    var order_side: OrderSide
    var amount: Fixed
    var price: Fixed

    fn __init__(
        out self,
        symbol: String,
        order_type: OrderType,
        order_side: OrderSide,
        amount: Fixed,
        price: Fixed,
    ):
        self.symbol = symbol
        self.order_type = order_type
        self.order_side = order_side
        self.amount = amount
        self.price = price


@value
struct CancelOrderRequestData:
    var symbol: String
    var order_id: String

    fn __init__(out self, symbol: String, order_id: String):
        self.symbol = symbol
        self.order_id = order_id


@value
struct CustomRequestData:
    var name: String
    var data: Dict[String, Any]

    fn __init__(out self, name: String):
        self.name = name
        self.data = Dict[String, Any]()

    fn __init__(out self, name: String, data: Dict[String, Any]):
        self.name = name
        self.data = data

    fn __setitem__(mut self, key: String, value: Any):
        self.data[key] = value

    fn __getitem__(self, key: String) raises -> Any:
        return self.data[key]


@value
struct AsyncTradingRequest:
    var type: Int  # 0-下单 1-撤单 9-自定义
    var data: Variant[
        CreateOrderRequestData, CancelOrderRequestData, CustomRequestData
    ]
    var exchange_id: ExchangeId
    var exchange: UnsafePointer[UInt8]

    fn __init__[
        T: Exchangeable
    ](
        out self,
        type: Int,
        data: Variant[
            CreateOrderRequestData,
            CancelOrderRequestData,
            CustomRequestData,
        ],
        exchange: UnsafePointer[T],
    ):
        self.type = type
        self.data = data
        self.exchange_id = exchange[].id()
        self.exchange = exchange.bitcast[UInt8]()

    fn bitcast[T: Exchangeable](self) -> UnsafePointer[T]:
        return self.exchange.bitcast[T]()


alias _ASYNC_TRADING_CHANNEL = _Global[
    "_ASYNC_TRADING_CHANNEL",
    Channel,
    _init_async_trading_channel,
]


fn _init_async_trading_channel() -> Channel:
    return Channel(1024)


fn async_trading_channel_ptr() -> UnsafePointer[Channel]:
    return _ASYNC_TRADING_CHANNEL.get_or_create_ptr()


fn save_text_to_file(file_name: String, text: String):
    """Save text to file."""
    try:
        with open(file_name, "w") as f:
            f.write(text)
    except e:
        print("save_text_to_file error: " + String(e))
