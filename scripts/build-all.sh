mojo build ccxt-bitmex-demo.mojo
mojo build ccxt-gateio-demo.mojo
mojo build gateio-main-async.mojo
mojo build gateio-main.mojo
mojo build gateio-ws.mojo
mojo build monoio-connect-demo.mojo
mojo build memory_leak.mojo

./build.sh ccxt-bitmex-demo.mojo
./build.sh ccxt-gateio-demo.mojo
./build.sh gateio-main-async.mojo
./build.sh gateio-main.mojo
./build.sh gateio-ws.mojo
./build.sh monoio-connect-demo.mojo
./build.sh memory_leak.mojo

mojo test
