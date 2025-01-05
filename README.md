# furnace
Furnace is a high-performance quantitative trading library that provides features similar to CCXT, allowing developers to connect and interact with multiple cryptocurrency exchanges easily. It offers a simple API for efficient strategy development and deployment.

## Installation

Before using furnace, you need to:

1. Compile https://github.com/furnace-dev/sonic-mojo and copy `libsonic.so` to the current directory.

2. Compile https://github.com/furnace-dev/furnace-connect and copy `libfurnace_connect.so` to the current directory.

```bash
magic install
magic shell
source init.sh
```

## Testing

```bash
mojo test
```

## Usage

```bash
# Debug mode
mojo run -D DEBUG_MODE ccxt-gateio-demo.mojo

# Release mode
mojo run ccxt-gateio-demo.mojo
```