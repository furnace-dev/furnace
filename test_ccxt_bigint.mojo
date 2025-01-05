from testing import assert_equal, assert_true, assert_raises
from exp.bigint import BigInt


fn test_init() raises:
    num = BigInt()
    assert_true(num.size == 1)
    assert_true(num.capacity == 4)
    assert_true(num.sign == False)


fn test_init_from_int() raises:
    num = BigInt(1234567890)
    assert_true(num.sign == False)
    assert_equal(num.to_string(), "1234567890")


fn test_init_from_string() raises:
    num = BigInt("1234567890")
    assert_true(num.sign == False)
    assert_equal(num.to_string(), "1234567890")


fn test_eq() raises:
    num1 = BigInt("1234567890")
    num2 = BigInt("1234567890")
    assert_true(num1 == num2)


fn test_ne() raises:
    num1 = BigInt("1234567890")
    num2 = BigInt("1234567891")
    assert_true(num1 != num2)


fn test_add() raises:
    num1 = BigInt("1234567890")
    num2 = BigInt("1234567890")
    num3 = num1 + num2
    assert_equal(num3.to_string(), "2469135780")


fn test_sub() raises:
    num1 = BigInt("1234567890")
    num2 = BigInt("1234567890")
    num3 = num1 - num2
    assert_equal(num3.to_string(), "0")


# fn test_mul() raises:
#     num1 = BigInt("1234567890")
#     num2 = BigInt("1234567890")
#     num3 = num1 * num2
#     assert_equal(num3.data[0], 1524138274549)
