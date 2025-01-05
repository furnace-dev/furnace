@value
@register_passable("trivial")
struct MessageType(Stringable):
    var _value: Int8

    alias EmptyMessage = MessageType(0)

    # error
    alias ErrorMessage = MessageType(1)
    alias EventNotifyMessage = MessageType(2)

    # 行情
    alias TickerMessage = MessageType(3)
    alias OrderbookMessage = MessageType(4)
    alias TradeMessage = MessageType(5)

    # 订单推送
    alias OrderMessage = MessageType(6)

    # 账户信息推送
    alias SpotPositionMessage = MessageType(7)
    alias FuturePositionMessage = MessageType(8)

    # 获取交易对
    alias PairRequestMessage = MessageType(9)
    # onPair
    alias PairMessage = MessageType(10)

    # 交易对上架下架
    alias PairChangeMessage = MessageType(11)

    # 设置杠杆
    alias SetLeverageRequestMessage = MessageType(12)
    # 设置持仓方向
    alias SetPositionSideRequestMessage = MessageType(13)
    # // onError only

    # 设置全仓
    alias SetCrossRequestMessage = MessageType(14)
    # 设置多币种保证金
    alias SetMultiMarginRequestMessage = MessageType(15)

	# //// SetMultiMargin
    alias PostOrderRequestMessage = MessageType(16)
    alias OrderRequestMessage = MessageType(17)
    # // onOrder
    # // maybe respone needed

	# //// CancelOrder
    alias CancelOrderRequestMessage = MessageType(18)
	# // onError only

	# //// CancelAllOrder
    alias CancelAllOrderRequestMessage = MessageType(19)
	# // onError only

	# //// GetOrder
    alias GetOrderRequestMessage = MessageType(20)
	# // onOrder

	# //// GetOpenOrders
    alias GetOpenOrdersRequestMessage = MessageType(21)
	# // onOrder

	# //// GetPositions
    alias GetPositionsRequestMessage = MessageType(22)
	# // onPosition

	# //// GetAccount
    alias GetAccountRequestMessage = MessageType(23)

	# // //// CheckAvaliable
	# // CheckAvaliableRequestMessage
	# // // 状态改变时，通过回调通知即可

	# // 用于继续编码
	# MessageTypeEnd

    fn __eq__(self, other: MessageType) -> Bool:
        return self._value == other._value

    fn __str__(self) -> String:
        if self == MessageType.ErrorMessage:
            return "ErrorMessage"
        elif self == MessageType.EventNotifyMessage:
            return "EventNotifyMessage"
        elif self == MessageType.TickerMessage:
            return "TickerMessage"
        elif self == MessageType.OrderbookMessage:
            return "OrderBookMessage"
        elif self == MessageType.TradeMessage:
            return "TradeMessage"
        elif self == MessageType.OrderMessage:
            return "OrderMessage"
        elif self == MessageType.PairRequestMessage:
            return "PairRequestMessage"
        elif self == MessageType.PairMessage:
            return "PairMessage"
        elif self == MessageType.PairChangeMessage:
            return "PairChangeMessage"
        elif self == MessageType.SetLeverageRequestMessage:
            return "SetLeverageRequestMessage"
        elif self == MessageType.SetPositionSideRequestMessage:
            return "SetPositionSideRequestMessage"
        elif self == MessageType.SetCrossRequestMessage:
            return "SetCrossRequestMessage"
        elif self == MessageType.SetMultiMarginRequestMessage:
            return "SetMultiMarginRequestMessage"
        elif self == MessageType.OrderRequestMessage:
            return "OrderRequestMessage"
        elif self == MessageType.CancelOrderRequestMessage:
            return "CancelOrderRequestMessage"
        elif self == MessageType.CancelAllOrderRequestMessage:
            return "CancelAllOrderRequestMessage"
        elif self == MessageType.GetOrderRequestMessage:
            return "GetOrderRequestMessage"
        elif self == MessageType.GetOpenOrdersRequestMessage:
            return "GetOpenOrdersRequestMessage"
        elif self == MessageType.GetPositionsRequestMessage:
            return "GetPositionsRequestMessage"
        elif self == MessageType.GetAccountRequestMessage:
            return "GetAccountRequestMessage"
        else:
            return "Unknown"
