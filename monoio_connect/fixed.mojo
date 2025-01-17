from memory import UnsafePointer
from .internal.fixed12 import fixed12_truediv, fixed12_mul


alias FIXED_SCALE_I = 1000000000000
alias FIXED_SCALE_F = 1000000000000.0
alias MAX_FRAC_BITS_12 = 12


@value
@register_passable
struct Fixed(Stringable):
    alias zero = Fixed(0)
    alias one = Fixed(1)
    alias two = Fixed(2)
    alias three = Fixed(3)
    alias four = Fixed(4)
    alias five = Fixed(5)
    alias six = Fixed(6)
    alias seven = Fixed(7)
    alias eight = Fixed(8)
    alias nine = Fixed(9)
    alias ten = Fixed(10)

    var _value: Int64

    fn __init__(out self):
        self._value = 0

    fn __init__(out self, v: Int64):
        self._value = FIXED_SCALE_I * v

    fn __init__(out self, v: Int):
        self._value = FIXED_SCALE_I * v

    fn __init__(out self, v: Float64):
        self._value = Int64(int(v * FIXED_SCALE_F))

    fn __init__(out self, v: String):
        if len(v) == 0:
            self._value = 0
            return
        try:
            self._value = fixed12_new_string(v)
        except:
            self._value = 0

    fn copy_from(mut self, other: Self):
        self._value = other._value

    @staticmethod
    fn from_value(value: Int64) -> Self:
        return Self {
            _value: value,
        }

    @always_inline
    fn is_zero(self) -> Bool:
        return self._value == 0

    @always_inline
    fn value(self) -> Int64:
        return self._value

    @always_inline
    fn to_int(self) -> Int:
        return int(self._value / FIXED_SCALE_I)

    @always_inline
    fn to_float(self) -> Float64:
        return self._value.cast[DType.float64]() / FIXED_SCALE_F

    @always_inline
    fn to_string(self) -> String:
        return fixed12_to_string(self._value)

    @always_inline
    fn round_to_fractional(self, scale: Self) -> Self:
        var v = fixed12_round_to_fractional(self._value, int(scale._value))
        return Self {
            _value: v,
        }

    @always_inline
    fn round(self, decimal_places: Int) -> Self:
        var v = fixed12_round(self._value, decimal_places)
        return Self {
            _value: v,
        }

    fn __abs__(self) -> Self:
        var v = -self._value if self._value < 0 else self._value
        return Self {_value: v}

    fn __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: Self) -> Bool:
        return self._value != other._value

    fn __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    fn __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    fn __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    fn __ge__(self, other: Self) -> Bool:
        return self._value >= other._value

    fn __neg__(self) -> Self:
        # -a
        return Self {_value: -self._value}

    fn __add__(self, other: Self) -> Self:
        # a + b
        return Self {_value: self._value + other._value}

    fn __iadd__(mut self, other: Self):
        # a += b
        self._value += other._value

    fn __sub__(self, other: Self) -> Self:
        # a - b
        return Self {_value: self._value - other._value}

    fn __isub__(mut self, other: Self):
        # a -= b
        self._value -= other._value

    fn __mul__(self, other: Self) -> Self:
        # a * b
        var v = fixed12_mul(self._value, other._value)
        return Self {_value: v}

    fn __imul__(mut self, other: Self):
        # a *= b
        self._value = fixed12_mul(self._value, other._value)

    fn __truediv__(self, other: Self) -> Self:
        # a / b
        var v = fixed12_truediv(self._value, other._value)
        return Self {_value: v}

    fn __itruediv__(mut self, other: Self):
        # a /= b
        self._value = fixed12_truediv(self._value, other._value)

    fn __str__(self) -> String:
        return self.to_string()


@always_inline
fn fixed12_new_string(s: String) raises -> Int64:
    """Create a Fixed12 from a string."""
    var sign: Int64 = -1 if s[0] == "-" else 1
    var s_ = s[1:] if sign == -1 else s
    var period = s_.find(".")

    var i: Int64 = 0
    var f: Int64 = 0

    if period == -1:
        i = atol(s_)
    else:
        if period > 0:
            i = atol(s_[0:period])
        var fs = s_[period + 1 :]
        if len(fs) > MAX_FRAC_BITS_12:
            var decimalPart = atol(fs[0 : MAX_FRAC_BITS_12 + 1])
            if decimalPart % 10 >= 5:
                fs = str(decimalPart / 10 + 1)
            else:
                fs = str(decimalPart / 10)
            fs = fs[0:MAX_FRAC_BITS_12]
        else:
            fs += "0" * (MAX_FRAC_BITS_12 - len(fs))
        f = atol(fs[0:MAX_FRAC_BITS_12])
    return sign * (i * FIXED_SCALE_I + f)


@always_inline
fn fixed12_int_part(fixed: Int64) -> Int64:
    return fixed / FIXED_SCALE_I


@always_inline
fn fixed12_frac_part(fixed: Int64) -> Int64:
    return fixed % FIXED_SCALE_I


@always_inline
fn fixed12_to_string(fixed: Int64) -> String:
    """Convert a Fixed12 to a string."""
    var result = String("")
    var isNegative = fixed < 0
    var fixed_ = -fixed if isNegative else fixed
    var intPart = fixed12_int_part(fixed_)

    if intPart == 0:
        result = "0"
    else:
        while intPart > 0:
            result = chr(int(ord("0") + intPart % 10)) + result
            intPart /= 10

    if isNegative:
        result = "-" + result

    var fracPart_ = fixed12_frac_part(fixed_)
    if fracPart_ > 0:
        result += "."
        var fracPart = str(fracPart_)
        var fracPartLength = len(fracPart)
        var zerosToAdd = MAX_FRAC_BITS_12 - fracPartLength
        if zerosToAdd > 0:
            result += "0" * zerosToAdd
        var fracPartN = 0
        for i in range(fracPartLength - 1, 0, -1):
            if fracPart[i] == "0":
                fracPartN += 1
            else:
                break
        result += fracPart[0 : fracPartLength - fracPartN]

    return result


@always_inline
fn fixed12_round_to_fractional(a: Int64, scale: Int) -> Int64:
    """Rounds to a fractional number with a given scale."""
    return int(round(float(a) / float(scale)) * float(scale))


@always_inline
fn fixed12_round(a: Int64, decimalPlaces: Int) -> Int64:
    """Rounds to a given number of decimal places."""
    var scale = pow(10, MAX_FRAC_BITS_12 - decimalPlaces)
    return int(round(float(a) / float(scale)) * float(scale))
