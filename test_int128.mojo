from testing import assert_equal, assert_true, assert_raises
from exp.int128 import Int128


fn test_init_from_lower_upper() raises:
    num = Int128(10, 20)
    assert_true(num.lower == 10)
    assert_true(num.upper == 20)

# fn test_init_from_Int() raises:
#     num = Int128(0x123456789ABCDEF0)
#     assert_true(num.lower == 0x789ABCDEF0)
#     assert_true(num.upper == 0x0000000000123456)

fn test_init_from_string_single_part() raises:
    num = Int128("10")
    assert_true(num.lower == 10)
    assert_true(num.upper == 0)

fn test_init_from_string_two_parts() raises:
    num = Int128("10.5")
    assert_true(num.lower == 10)
    assert_true(num.upper == 5)

fn test_init_from_invalid_string() raises:
    try:
        _ = Int128("invalid")
    except e:
        assert_equal(String(e), "String is not convertible to integer with base 10: 'invalid'")

fn test_eq() raises:
    num1 = Int128(10, 20)
    num2 = Int128(10, 20)
    num3 = Int128(5, 15)
    assert_true(num1 == num2)
    assert_true(num1 != num3)

fn test_gt_lt() raises:
    num1 = Int128(10, 20)
    num2 = Int128(15, 20)
    num3 = Int128(10, 25)
    assert_true(num1 < num2)
    assert_true(num1 < num3)
    assert_true(num2 > num1)
    assert_true(num3 > num1)

fn test_add() raises:
    num1 = Int128(10, 20)
    num2 = Int128(5, 15)
    result = num1 + num2
    assert_true(result.lower == 15)
    assert_true(result.upper == 35)

fn test_sub() raises:
    num1 = Int128(10, 20)
    num2 = Int128(5, 15)
    result = num1 - num2
    assert_true(result.lower == 5)
    assert_true(result.upper == 5)

fn test_abs() raises:
    num = Int128(10, -20)
    result = abs(num)
    assert_equal(String(result), "1918446744073709551606")

fn test_String() raises:
    num = Int128(10, 20)
    assert_equal(String(num), "2010")

fn test_repr() raises:
    num = Int128(10, 20)
    assert_equal(repr(num), "2010")


# fn test_from_Int() raises:
#     num = Int128(10)
#     # assert_equal(String(num), "10")
