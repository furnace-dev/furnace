@value
struct Pair(Stringable):
    var symbol: String
    var base: String
    var quote: String

    # 交易规则
    var min_quantity: Float64  # 系统最小交易数量
    var min_value: Float64  # 系统最小交易价值
    var max_quantity: Float64  # 系统最大交易数量
    var max_value: Float64  # 系统最大交易价值
    var quote_tick: Float64  # 系统价格最小变化单位
    var base_tick: Float64  # 系统数量最小变化单位
    var quote_precision: Int64  # 系统价格位数
    var base_precision: Int64  # 系统数量位数
    var quote_multiplier: Float64  # 系统价格 * QuoteMultiplier = 单位价格
    var base_multiplier: Float64  # 系统数量 * BaseMultiplier = 单位数量
    # 杠杆和持仓限制（本系统一般不使用10倍以上杠杆）
    var max_leverage: Float64  # 杠杆倍数
    var max_notional: Float64  # 最大成交额

    fn __str__(self) -> String:
        return String.write(
            " base: ",
            self.base,
            " quote: ",
            self.quote,
            " symbol: ",
            self.symbol,
            " min_quantity: ",
            self.min_quantity,
            " min_value: ",
            self.min_value,
            " quote_tick: ",
            self.quote_tick,
            " base_tick: ",
            self.base_tick,
            " quote_precision: ",
            self.quote_precision,
            " base_precision: ",
            self.base_precision,
            " quote_multiplier: ",
            self.quote_multiplier,
            " base_multiplier: ",
            self.base_multiplier,
            " max_leverage: ",
            self.max_leverage,
            " max_notional: ",
            self.max_notional,
        )
