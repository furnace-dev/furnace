from testing import assert_equal, assert_true, assert_raises
from sonic import *


fn test_auth_json_parse() raises:
    var text = '{"req_id":"637267887005765","success":true,"ret_msg":"","op":"auth","conn_id":"ct7b5b9qo29o0l72ltjg-4r9wz"}'
    var json_obj = JsonObject(text)
    var op = json_obj.get_str("op")
    assert_equal(op, "auth")
    var s = "success"
    var success = json_obj.get_bool(s)
    print("success: " + String(success))
    assert_equal(success, True)
    _ = json_obj^


fn main() raises:
    test_auth_json_parse()
