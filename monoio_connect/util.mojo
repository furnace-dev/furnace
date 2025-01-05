fn parse_bool(val: String) -> Bool:
    """Parse a string as a boolean value.

    The string is considered `True` if it is equal to "True" or "true" (case
    insensitive). Otherwise, it is considered `False`.
    """
    return val.lower() == "true"