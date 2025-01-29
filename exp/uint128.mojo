@value
struct UInt128(Stringable, Representable):
    """UHugeints are composed of a (lower, upper) component."""

    var lower: UInt64
    var upper: UInt64

    fn __str__(self) -> String:
        return "lower: " + String(self.lower) + ", upper: " + String(self.upper)

    fn __repr__(self) -> String:
        return "UInt128(" + String(self.lower) + ", " + String(self.upper) + ")"
