# https://github.com/shabbyrobe/go-num

alias signBit = 0x8000000000000000


@value
struct Int128(Stringable, Representable):
    """Hugeints are composed of a (lower, upper) component.

    The value of the hugeint is upper * 2^64 + lower
    For easy usage, the functions duckdb_hugeint_to_double/duckdb_double_to_hugeint are recommended
    """

    var lower: UInt64
    var upper: Int64

    fn __init__(out self, lower: UInt64, upper: Int64):
        self.lower = lower
        self.upper = upper

    fn __init__(out self, value: Int):
        self.lower = value & 0xFFFFFFFFFFFFFFFF
        self.upper = value >> 64

    fn __init__(out self, value: String) raises:
        var parts = value.split(".")
        if len(parts) == 1:
            self.lower = Int(parts[0])
            self.upper = 0
        elif len(parts) == 2:
            self.lower = Int(parts[0])
            self.upper = Int(parts[1])
        else:
            raise Error("Invalid string format for Int128")

    fn __eq__(self, other: Self) -> Bool:
        return self.lower == other.lower and self.upper == other.upper

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __gt__(self, other: Self) -> Bool:
        return self.upper > other.upper or (
            self.upper == other.upper and self.lower > other.lower
        )

    fn __ge__(self, other: Self) -> Bool:
        return self > other or self == other

    fn __lt__(self, other: Self) -> Bool:
        return other > self

    fn __le__(self, other: Self) -> Bool:
        return other >= self

    # Abs returns the absolute value of i as a signed integer.
    #
    # If i == MinI128, overflow occurs such that Abs(i) == MinI128.
    # If this is not desired, use AbsU128.
    #
    fn __abs__(self) -> Self:
        var result = self
        if result.upper < 0:  # Check if negative using sign bit
            # Two's complement negation
            result.upper = ~result.upper
            result.lower = ~(result.lower - 1)
            if result.lower == 0:  # Handle carry
                result.upper += 1
        return result

    fn __add__(self, other: Self) -> Self:
        var lower = self.lower + other.lower
        var upper = self.upper + other.upper + (1 if lower < self.lower else 0)
        return Int128(lower, upper)

    fn __sub__(self, other: Self) -> Self:
        var lower = self.lower - other.lower
        var upper = self.upper - other.upper - (1 if lower > self.lower else 0)
        return Int128(lower, upper)

    fn __mul__(self, other: Self) -> Self:
        var lower = self.lower * other.lower
        var upper = self.upper * other.upper
        return Int128(lower, upper)

    fn __div__(self, other: Self) -> Self:
        var lower = self.lower // other.lower
        var upper = self.upper // other.upper
        return Int128(lower, upper)

    fn __truediv__(self, other: Self) -> Self:
        var lower = self.lower // other.lower
        var upper = self.upper // other.upper
        return Int128(lower, upper)

    fn __mod__(self, other: Self) -> Self:
        var lower = self.lower % other.lower
        var upper = self.upper % other.upper
        return Int128(lower, upper)

    fn to_string(self) -> String:
        # Handle special case of zero
        if self.upper == 0 and self.lower == 0:
            return "0"

        # Check if negative
        var is_negative = self.upper < 0
        var result = self

        if is_negative:
            # Two's complement negation to get positive value
            result.upper = ~result.upper
            result.lower = ~(result.lower - 1)
            if result.lower == 0:
                result.upper += 1

        # Convert to string
        var value: String
        if result.upper > 0:
            value = String(result.upper) + String(result.lower)
        else:
            value = String(result.lower)

        # Add negative sign if needed
        if is_negative:
            value = "-" + value

        return value

    fn __str__(self) -> String:
        return self.to_string()

    fn __repr__(self) -> String:
        #return "Int128(" + String(self.lower) + ", " + String(self.upper) + ")"
        return self.to_string()
