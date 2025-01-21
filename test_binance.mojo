from collections import Dict
from os import getenv
from testing import assert_equal, assert_true
from ccxt.base.types import *
from ccxt.foundation.bybit import Bybit
from ccxt.foundation.gate import Gate
from sonic import *
from monoio_connect import *


fn test_fetch_listen_key() raises:
    var text = '{"listenKey":"Vci3svYt8bavTKIBZ8CIviMuA2dtX7uMxVFlnKCPCSRPwrF1EpDp35lR0NWZrwLC"}'
    var doc = JsonObject(text)
    var code = doc.get_i64("code")
    assert_equal(code, 0)

    var listen_key = doc.get_str("listenKey")
    assert_true(len(listen_key) > 0)

    assert_equal(
        listen_key,
        "Vci3svYt8bavTKIBZ8CIviMuA2dtX7uMxVFlnKCPCSRPwrF1EpDp35lR0NWZrwLC",
    )
