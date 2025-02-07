#!/bin/bash

# Detect operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$(pwd)/.magic/envs/default/lib:$(pwd)/bin"
else
    # Linux
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/lib/x86_64-linux-gnu:$(pwd)/.magic/envs/default/lib:$(pwd)/bin"
fi

# export LD_PRELOAD=libsonic.so:libfurnace_connect.so
