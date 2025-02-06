# furnace
Furnace is a high-performance quantitative trading library that provides features similar to CCXT, allowing developers to connect and interact with multiple cryptocurrency exchanges easily. It offers a simple API for efficient strategy development and deployment.

## Prerequisites

Before using furnace, you need to:

1. Compile https://github.com/furnace-dev/sonic-mojo and copy `libsonic.so` to the current directory.

2. **Important**: The `libfurnace_connect.so` library is a commercial component. To purchase and obtain access:
   - Contact via WeChat: `chds27`
   - After purchase, compile https://github.com/furnace-dev/furnace-connect and copy `libfurnace_connect.so` to the current directory

3. Install system dependencies:
```bash
sudo apt-get install zlib1g-dev libtinfo-dev
```

## Install Magic

1. Install Magic using the official installer:
```bash
curl -ssL https://magic.modular.com/deb1e28c-0019-44c0-b2f9-743dee6ddb70 | bash
```

2. Run the `source` command that's printed in your terminal after installation.

3. Create and activate the project environment:
```bash
magic shell                      # Activate the environment
```

## Project Setup

Initialize the project dependencies:
```bash
source init.sh
```

## Testing

Run the test suite:
```bash
mojo test
```

## Usage

Run the demos in either debug or release mode:

```bash
# Debug mode
RUST_BACKTRACE=1 mojo run -D DEBUG_MODE gateio-demo.mojo
RUST_BACKTRACE=1 mojo run -D DEBUG_MODE gateio-main.mojo

# Release mode
mojo run ccxt-gateio-demo.mojo
```

## Documentation

For more information about Magic package manager, see the [official Magic documentation](https://docs.modular.com/magic/).