from .uint128 import UInt128


@value
struct Decimal(Stringable, Representable):
    """Decimals are composed of a width and a scale, and are stored in a hugeint.
    """

    var width: UInt8
    var scale: UInt8
    var value: UInt128

    fn __str__(self) -> String:
        return (
            "width: "
            + String(self.width)
            + ", scale: "
            + String(self.scale)
            + ", value: "
            + String(self.value)
        )

    fn __repr__(self) -> String:
        return (
            "Decimal("
            + String(self.width)
            + ", "
            + String(self.scale)
            + ", "
            + String(self.value)
            + ")"
        )
