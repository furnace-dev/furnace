import math


fn decimal_places(value: Float64) -> Int:
    """
    Return decimal places: 0.0001 -> 4.
    """
    if value == 0.0:
        return 0

    return int(math.ceil(math.log10(1.0 / value)))
