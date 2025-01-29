from testing import assert_equal, assert_raises
from pathlib import Path, _dir_of_current_file
from time import now
from vendor.emberjson import JSON, Object


fn test_list():
    l = List[String]()
    for i in range(10):  # 100_000
        l.append(String(i))

    start = now()
    s = String(",").join(l)
    end = now()
    print("Len: ", len(s), "Time: ", (end - start) / 1_000_000_000, "seconds")


fn test_json() raises:
    # parse string
    var s = '{"key": 123}'
    var json = JSON.from_string(s)

    print(json.is_object())  # prints true

    # fetch inner value
    var ob = json.object()
    print(ob["key"].Int())  # prints 123
    # implicitly acces json object
    print(json["key"].Int())  # prints 123

    # json array
    s = "[123, 456]"
    json = JSON.from_string(s)
    var arr = json.array()
    print(arr[0].Int())  # prints 123
    # implicitly access array
    print(json[1].Int())  # prints 456

    # `Value` type is formattable to allow for direct printing
    print(json[0])  # prints 123


fn test_json_ref() raises:
    var order_place_param = JSON()
    var a = Pointer.address_of(order_place_param.object())
    order_place_param.object()["i0"] = 11
    a[]["i"] = 100
    a[]["s"] = "hello"

    assert_equal(String(order_place_param), """{"i0":11,"i":100,"s":"hello"}""")


fn set_object[L: MutableOrigin](ref [L]a: Object):
    a["a"] = 100


fn test_object_ref() raises:
    var order_place_param = JSON()
    var o = Pointer.address_of(order_place_param.object())
    set_object(o[])
    assert_equal(String(order_place_param), """{"a":100}""")
