# for linux
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib/x86_64-linux-gnu:$(realpath .magic/envs/default/lib):$(realpath .)

# for macos
#export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/.magic/envs/default/lib:$(pwd)"

# export LD_PRELOAD=libsonic.so:libfurnace_connect.so
