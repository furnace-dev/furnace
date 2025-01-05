# https://github.com/shabbyrobe/go-num
# https://github.com/bgreni/MojoBigInt/blob/main/bignum/bigint.mojo


@value
struct Int128:
    var hi: UInt64
    var lo: UInt64

    fn __init__(out self, hi: UInt64, lo: UInt64):
        self.hi = hi
        self.lo = lo

    fn __init__(out self, v: Int64):
        # There's a no-branch way of calculating this:
        #   out.lo = uint64(v)
        #   out.hi = ^((out.lo >> 63) + maxUint64)
        #
        # There may be a better one than that, but that's the one I found. Bogus
        # microbenchmarks on an i7-3820 and an i7-6770HQ showed it may possibly be
        # slightly faster, but at huge cost to the inliner. The no-branch
        # version eats 20 more points out of Go 1.12's inlining budget of 80 than
        # the 'if v < 0' verson, which is probably worse overall.

        var hi = UInt64(0)
        if v < 0:
            hi = UInt64.MAX
        self.hi = hi
        self.lo = UInt64(int(v))

    fn __init__(out self, v: Int32):
        self.__init__(Int64(int(v)))

    fn __init__(out self, v: Int16):
        self.__init__(Int64(int(v)))

    fn __init__(out self, v: Int8):
        self.__init__(Int64(int(v)))

    fn __init__(out self, v: Int):
        self.__init__(Int64(int(v)))

    fn __init__(out self, v: UInt64):
        self.hi = 0
        self.lo = v

    fn __init__(out self, v: String) raises:
        # Parse string to Int128
        # Handle empty string
        if len(v) == 0:
            self.hi = 0
            self.lo = 0
            return

        # Handle negative sign
        var is_negative = False
        var start = 0
        if v[0] == '-':
            is_negative = True
            start = 1
        elif v[0] == '+':
            start = 1

        # Parse digits
        var result = Int128(0)
        for i in range(start, len(v)):
            var digit = ord(v[i]) - ord('0')
            if digit < 0 or digit > 9:
                raise Error("Invalid digit in string")
            
            # Multiply by 10 and add digit
            var temp = result
            for _ in range(9):
                temp = temp + result
            result = temp + Int128(UInt64(digit))

        # Apply negative sign if needed
        if is_negative:
            result = Int128(~result.hi, ~result.lo)
            result = result + Int128(0, 1)

        self.hi = result.hi
        self.lo = result.lo
    
    fn __str__(self) -> String:
        # Handle zero case
        if self.hi == 0 and self.lo == 0:
            return "0"

        # Handle negative numbers
        var is_negative = self.hi < 0
        var value = self
        if is_negative:
            # Two's complement negation
            value = Int128(~value.hi, ~value.lo)
            value = value + Int128(0, 1)

        # Convert to string by repeatedly dividing by 10
        var result = ""
        var current = value
        while current.hi != 0 or current.lo != 0:
            var remainder = current.lo % 10
            current = Int128(current.hi / 10, current.lo / 10)
            result = String(chr(ord('0') + remainder)) + result

        # Add negative sign if needed
        if is_negative:
            result = "-" + result

        return result
    
    fn __eq__(self, other: Self) -> Bool:
        return self.hi == other.hi and self.lo == other.lo
    
    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)
    
    fn __add__(self, other: Self) -> Self:
        var lo = self.lo + other.lo
        var carry = 1 if lo < self.lo else 0
        var hi = self.hi + other.hi + carry
        return Int128(hi, lo)

    fn __sub__(self, other: Self) -> Self:
        var lo = self.lo - other.lo
        var borrow = 1 if lo > self.lo else 0
        var hi = self.hi - other.hi - borrow
        return Int128(hi, lo)
    