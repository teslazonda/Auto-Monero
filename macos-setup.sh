#!/bin/bash

# Auto-Monero  Copyright (C) 2024 teslazonda
# This program comes with ABSOLUTELY NO WARRANTY;
# This is free software, and you are welcome to redistribute it under certain conditions.

cd ~ 
echo "Create Monero-Stuff directory"
mkdir Monero-Stuff && cd Monero-Stuff

echo "Creating Monero-Stuff directory here:"
pwd
sleep 2

# Install Homebrew
echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo "Update all packages"

sleep 2
brew update && brew upgrade

echo "Install XMRig dependencies"
brew install cmake wget automake libtool autoconf libuv openssl hwloc
sleep 2

echo "Install xmrig"
git clone https://github.com/xmrig/xmrig.git
sleep 2

echo "Make xmrig donation 0%"
cd xmrig/src && sed -i 's/1/0/g' donate.h && cd ../../
pwd


echo "creating xmrig build and entering xmrig/scripts folder"
mkdir xmrig/build && cd xmrig/scripts
pwd
sleep 2

./build.hwloc.sh && cd ../build
cmake .. -DOPENSSL_ROOT_DIR=$(brew --prefix openssl) -DHWLOC_INCLUDE_DIR=../scripts/deps/include -DHWLOC_LIBRARY=../scripts/deps/lib/libhwloc.a
make -j$(sysctl -n hw.logicalcpu)

