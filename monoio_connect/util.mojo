fn parse_bool(value: String) -> Bool:
    """Parse a string value into a boolean.

    Args:
        value: String value to parse, e.g. "True", "true", "1".

    Returns:
        Bool: True if value is "True", "true", "1", False otherwise.
    """
    var lower_value = value.lower()
    return lower_value == "true" or lower_value == "1"
