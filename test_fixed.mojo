from testing import assert_equal, assert_true, assert_raises
from monoio_connect import Fixed
from monoio_connect.fixed import fixed12_to_string, fixed12_round_to_fractional, fixed12_round


fn test_empty_string() raises:
    var p1 = Fixed("")
    assert_equal(str(p1), "0")


fn test_initialization() raises:
    var p1 = Fixed("123.456")
    assert_equal(str(p1), "123.456")

    var p2 = Fixed(123)
    assert_equal(str(p2), "123")


fn test_addition() raises:
    var p1 = Fixed("1.1")
    var p2 = Fixed("2.2")
    var result = p1 + p2
    assert_equal(str(result), "3.3")


fn test_subtraction() raises:
    var p1 = Fixed("5.5")
    var p2 = Fixed("2.2")
    var result = p1 - p2
    assert_equal(str(result), "3.3")


fn test_multiplication() raises:
    var p1 = Fixed("2.5")
    var p2 = Fixed("4.0")
    var result = p1 * p2
    assert_equal(str(result), "10")


fn test_division() raises:
    var p1 = Fixed("10.0")
    var p2 = Fixed("2.0")
    var result = p1 / p2
    assert_equal(str(p1), "10")
    assert_equal(str(p2), "2")
    assert_equal(str(result), "5")

    # 测试除后有小数
    var p3 = Fixed("10.0")
    var p4 = Fixed("3.0")
    assert_equal(str(p3 / p4), "3.333333333333")

    # 测试两个小数相除
    var p5 = Fixed("1.2")
    var p6 = Fixed("3.6")
    assert_equal(str(p5 / p6), "0.333333333333")


fn test_modulus() raises:
    var p1 = Fixed("5.5")
    var p2 = Fixed("2.0")
    # TODO: 添加对取模的支持
    # var result = p1 % p2
    # assert_equal(str(result), "1.5")


fn test_negation() raises:
    var p1 = Fixed("3.5")
    var result = -p1
    assert_equal(str(result), "-3.5")


fn test_absolute() raises:
    var p1 = Fixed("-3.5")
    var result = abs(p1)
    assert_equal(str(result), "3.5")


fn test_comparisons() raises:
    var p1 = Fixed("1.0")
    var p2 = Fixed("2.0")
    assert_true(p1 < p2)
    assert_true(p2 > p1)
    assert_true(p1 <= p1)
    assert_true(p1 >= p1)
    assert_true(p1 != p2)


fn test_string_operations() raises:
    assert_true(Fixed("1.1") + Fixed("2.2") == Fixed("3.3"))
    assert_true(Fixed("5.5") - Fixed("2.2") == Fixed("3.3"))
    assert_true(Fixed("2.5") * Fixed("4.0") == Fixed("10.0"))
    assert_true(Fixed("10.0") / Fixed("20.0") == Fixed("0.5"))
    var result = Fixed("10.0") / Fixed("2.0")
    assert_equal(str(result), "5")


fn test_edge_cases() raises:
    var p1 = Fixed("0.0")
    var p2 = Fixed("0.0")
    assert_equal(str(p1 + p2), "0")
    assert_equal(str(p1 - p2), "0")
    assert_equal(str(p1 * p2), "0")
    # with assert_raises(contains="Integer Division by zero."):
    #     var result = Fixed("10.0") / Fixed("0.0")
    #     assert_equal(str(result), "0")


fn test_precise_string_conversion() raises:
    var p1 = Fixed("1")
    var p2 = Fixed(1)
    assert_equal(str(p1), str(p2))


# 测试范围，最大: 999999.999999999999
fn test_max() raises:
    var p1 = Fixed("999999.999999999999")
    assert_equal(str(p1), "999999.999999999999")
    var p2 = Fixed("111111.111111111111")
    var p3 = p1 - p2
    assert_equal(str(p3), "888888.888888888888")
    var p4 = Fixed(3)
    var p5 = p4 * p2
    assert_equal(str(p5), "333333.333333333333")

    var p6 = p5.to_float()
    assert_equal(p6, 333333.333333333333)

    var p7 = Fixed("-1.123456789012345678")
    assert_equal(str(p7), "-1.123456789012")


fn test_fixed12_round_to_fractional() raises:
    assert_equal(fixed12_round_to_fractional(12345, 100), 12300)
    var p1 = 1123456789012
    assert_equal(p1, 1123456789012)
    assert_equal(fixed12_round_to_fractional(p1, 1), 1123456789012)
    assert_equal(fixed12_round_to_fractional(p1, 10), 1123456789010)
    assert_equal(fixed12_round_to_fractional(p1, 100), 1123456789000)
    assert_equal(fixed12_round_to_fractional(p1, 1000), 1123456789000)
    assert_equal(fixed12_round_to_fractional(p1, 10000), 1123456790000)
    assert_equal(fixed12_round_to_fractional(p1, 100000), 1123456800000)


fn test_round_to_fractional() raises:
    var p1 = Fixed("1.123456789012")
    assert_equal(str(p1.round_to_fractional(Fixed(10000))), "0")
    assert_equal(str(p1.round_to_fractional(Fixed(1000))), "0")
    assert_equal(str(p1.round_to_fractional(Fixed(100))), "0")
    assert_equal(str(p1.round_to_fractional(Fixed(10))), "0")
    assert_equal(str(p1.round_to_fractional(Fixed(1))), "1")
    assert_equal(str(p1.round_to_fractional(Fixed(0.1))), "1.1")
    assert_equal(str(p1.round_to_fractional(Fixed(0.01))), "1.12")
    assert_equal(str(p1.round_to_fractional(Fixed(0.001))), "1.123")
    assert_equal(str(p1.round_to_fractional(Fixed(0.0001))), "1.1235")
    assert_equal(str(p1.round_to_fractional(Fixed(0.00001))), "1.12346")
    assert_equal(str(p1.round_to_fractional(Fixed(0.000001))), "1.123457")
    assert_equal(str(p1.round_to_fractional(Fixed(0.0000001))), "1.1234568")
    assert_equal(str(p1.round_to_fractional(Fixed(0.00000001))), "1.12345679")
    assert_equal(str(p1.round_to_fractional(Fixed(0.000000001))), "1.123456789")
    assert_equal(
        str(p1.round_to_fractional(Fixed(0.0000000001))), "1.123456789"
    )
    assert_equal(
        str(p1.round_to_fractional(Fixed(0.00000000001))), "1.12345678901"
    )
    assert_equal(
        str(p1.round_to_fractional(Fixed(0.000000000001))), "1.123456789012"
    )


fn test_round() raises:
    var p1 = Fixed("1.123456789012")
    assert_equal(str(p1.round(0)), "1")
    assert_equal(str(p1.round(1)), "1.1")
    assert_equal(str(p1.round(2)), "1.12")
    assert_equal(str(p1.round(3)), "1.123")
    assert_equal(str(p1.round(4)), "1.1235")
    assert_equal(str(p1.round(5)), "1.12346")
    assert_equal(str(p1.round(6)), "1.123457")
    assert_equal(str(p1.round(7)), "1.1234568")
    assert_equal(str(p1.round(8)), "1.12345679")
    assert_equal(str(p1.round(9)), "1.123456789")
    assert_equal(str(p1.round(10)), "1.123456789")
    assert_equal(str(p1.round(11)), "1.12345678901")
    assert_equal(str(p1.round(12)), "1.123456789012")
