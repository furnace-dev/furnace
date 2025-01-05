@value
struct Ticker(Stringable):
    var exchange: Exchange
    var symbol: String
    var symbol_api: String
    var ask: Float64
    var bid: Float64
    var ask_quantity: Float64
    var bid_quantity: Float64
    var remote_time: Int64
    var local_time: Int64
    var update_id: Int64
    var ema: Float64
    var ma: Float64
    var fast_ma: Float64

    fn update(mut self, ticker: Ticker) -> None:
        self.ask = ticker.ask
        self.bid = ticker.bid
        self.ask_quantity = ticker.ask_quantity
        self.bid_quantity = ticker.bid_quantity
        self.remote_time = ticker.remote_time
        self.local_time = ticker.local_time
        self.update_id = ticker.update_id

    fn __str__(self) -> String:
        return String.write(
            " symbol: ",
            self.symbol_api,
            " ask: ",
            self.ask,
            " ask_quantity: ",
            self.ask_quantity,
            " bid: ",
            self.bid,
            " bid_quantity: ",
            self.bid_quantity,
            " remote_time: ",
            self.remote_time,
            " local_time: ",
            self.local_time,
            " update_id: ",
            self.update_id,
            " ma: ",
            self.ma,
            " ema: ",
            self.ema,
        )
