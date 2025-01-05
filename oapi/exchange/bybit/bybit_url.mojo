struct BybitSpotUrl:
    var spot_rest_host: String
    var spot_ws_host: String
    var wsapi: String

    fn __init__(
        out self, spot_rest_host: String, spot_ws_host: String, wsapi: String
    ):
        self.spot_rest_host = spot_rest_host
        self.spot_ws_host = spot_ws_host
        self.wsapi = wsapi


var bybit_spot_url_normal = BybitSpotUrl(
    spot_rest_host="https://api.bybit.com",
    spot_ws_host="wss://stream.bybit.com:9443",
    wsapi="wss://ws-api.bybit.com:443/ws-api/v3",
)


struct BybitUsdtSwapUrl:
    var usdt_swap_rest_host: String
    var usdt_swap_ws_public: String
    var usdt_swap_ws_private: String

    fn __init__(
        out self,
        usdt_swap_rest_host: String,
        usdt_swap_ws_public: String,
        usdt_swap_ws_private: String,
    ):
        self.usdt_swap_rest_host = usdt_swap_rest_host
        self.usdt_swap_ws_public = usdt_swap_ws_public
        self.usdt_swap_ws_private = usdt_swap_ws_private


var bybit_usdt_swap_url_normal = BybitUsdtSwapUrl(
    usdt_swap_rest_host="https://fapi.bybit.com",
    usdt_swap_ws_public="wss://ws.bybit.com:8443/ws/v5/public",
    usdt_swap_ws_private="wss://ws.bybit.com:8443/ws/v5/private",
)

var bybit_usdt_swap_url_colo = BybitUsdtSwapUrl(
    usdt_swap_rest_host="https://fapi-mm.bybit.com",
    usdt_swap_ws_public="wss://fstream-mm.bybit.com/ws",
    usdt_swap_ws_private="wss://ws-fapi-mm.bybit.com/ws-fapi/v1",
)
