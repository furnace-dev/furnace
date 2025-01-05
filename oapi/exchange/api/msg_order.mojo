from oapi.models import *


@value
struct PostOrderRequest:
    var order: Order
    var take_profit: Float64
    var stop_loss: Float64
    var reduce_only: Bool