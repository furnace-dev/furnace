from .base import Callbacks
from .ex_config import ExConfig
from .msg_pair import PairRequest
from oapi.models import *


trait Tradable:
    fn run(self) raises -> None:
        ...

    fn close(self) raises -> None:
        ...

    fn set_callbacks(self, callbacks: Callbacks) -> None:
        ...

    fn update_config(mut self, other: ExConfig) -> None:
        ...

    # 获取交易规则
    fn get_pairs(self, request: PairRequest) raises -> List[Pair]:
        ...

    ### 账户设置
    # 设置持仓杠杆
    # SetLeverage(message.SetLeverageRequest)
    # 设置持仓方向
    # SetPositionSide(message.SetPositionSideRequest)
    # 设置全仓
    # SetCross(message.SetCrossRequest)
    # 设置多币种保证金
    # SetMultiMargin(message.SetMultiMarginRequest)
    # todo: 统一保证金账户

    # Trade
    # PostOrder(message.PostOrderRequest)
    # CancelOrder(message.CancelOrderRequest)
    # CancelAllOrder(message.CancelAllOrderRequest)
    # GetOpenOrders(message.GetOpenOrdersRequest)
    # GetOrder(message.GetOrderRequest)

    # Account
    # GetAccount(message.GetAccountRequest) (spotPositions []position.SpotPosition, positions []position.FuturePosition, err error) // spot and future
    # todo:划转提现等，或者单独开一个api类别？这样策略就只需要发出请求

    # CheckAvaliable() # bool // 针对例如binance.spot的日订单限额
