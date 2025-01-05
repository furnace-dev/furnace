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
            + str(self.width)
            + ", scale: "
            + str(self.scale)
            + ", value: "
            + str(self.value)
        )

    fn __repr__(self) -> String:
        return (
            "Decimal("
            + str(self.width)
            + ", "
            + str(self.scale)
            + ", "
            + str(self.value)
            + ")"
        )
