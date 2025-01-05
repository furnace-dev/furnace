from testing import assert_equal, assert_true, assert_raises
from ccxt.base.precise import Precise


fn test_initialization() raises:
    var p1 = Precise("123.456")
    assert_equal(p1.integer, 123456)
    assert_equal(p1.decimals, 3)

    var p2 = Precise(123, 2)
    assert_equal(p2.integer, 123)
    assert_equal(p2.decimals, 2)


fn test_addition() raises:
    var p1 = Precise("1.1")
    var p2 = Precise("2.2")
    var result = p1 + p2
    assert_equal(str(result), "3.3")


fn test_subtraction() raises:
    var p1 = Precise("5.5")
    var p2 = Precise("2.2")
    var result = p1 - p2
    assert_equal(str(result), "3.3")


fn test_multiplication() raises:
    var p1 = Precise("2.5")
    var p2 = Precise("4.0")
    var result = p1 * p2
    assert_equal(str(result), "10")


fn test_division() raises:
    var p1 = Precise("10.0")
    var p2 = Precise("2.0")
    var result = p1 / p2
    assert_equal(str(p1), "10")
    assert_equal(str(p2), "2")
    assert_equal(str(result), "5")

    # 测试除后有小数
    var p3 = Precise("10.0")
    var p4 = Precise("3.0")
    assert_equal(str(p3 / p4), "3.3333333333")

    # 测试两个小数相除
    var p5 = Precise("1.2")
    var p6 = Precise("3.6")
    assert_equal(str(p5 / p6), "0.3333333333")


fn test_modulus() raises:
    var p1 = Precise("5.5")
    var p2 = Precise("2.0")
    var result = p1 % p2
    assert_equal(str(result), "1.5")


fn test_negation() raises:
    var p1 = Precise("3.5")
    var result = -p1
    assert_equal(str(result), "-3.5")


fn test_absolute() raises:
    var p1 = Precise("-3.5")
    var result = abs(p1)
    assert_equal(str(result), "3.5")


fn test_comparisons() raises:
    var p1 = Precise("1.0")
    var p2 = Precise("2.0")
    assert_true(p1 < p2)
    assert_true(p2 > p1)
    assert_true(p1 <= p1)
    assert_true(p1 >= p1)
    assert_true(p1 != p2)


fn test_string_operations() raises:
    assert_true(Precise.string_add("1.1", "2.2") == Precise("3.3"))
    assert_true(Precise.string_sub("5.5", "2.2") == Precise("3.3"))
    assert_true(Precise.string_mul("2.5", "4.0") == Precise("10.0"))
    assert_true(Precise.string_div("10.0", "20.0") == Precise("0.5"))
    var p1 = Precise("10")
    assert_equal(p1.integer, 10)
    assert_equal(p1.decimals, 0)
    assert_equal(p1.base, 10)
    var p2 = Precise("2")
    assert_equal(p2.integer, 2)
    assert_equal(p2.decimals, 0)
    assert_equal(p2.base, 10)
    var result = Precise.string_div("10.0", "2.0")
    assert_equal(str(result), "5")


fn test_edge_cases() raises:
    var p1 = Precise("0.0")
    var p2 = Precise("0.0")
    assert_equal(str(p1 + p2), "0")
    assert_equal(str(p1 - p2), "0")
    assert_equal(str(p1 * p2), "0")
    # with assert_raises(contains="division by zero"):
    #     _ = Precise.string_div("10.0", "0.0")
    var result = Precise.string_div("10.0", "0.0")
    assert_equal(str(result), "0")
    # assert_equal(str(p1 / p2), None)  # Division by zero should return


fn test_precise_string_conversion() raises:
    var p1 = Precise("1")
    var p2 = Precise(1)
    assert_equal(str(p1), str(p2))
