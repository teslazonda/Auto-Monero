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

echo "Update all packages"
sleep 2
sudo apt update && sudo apt upgrade -y

echo "Install XMRig dependencies"
sleep 2
sudo apt install git build-essential cmake automake libtool autoconf -y

# XMRig setup
git clone https://github.com/xmrig/xmrig.git
# Replace 1% donation with 0%
cd xmrig/src && sed -i 's/1/0/g' donate.h && cd ../../

mkdir xmrig/build && cd xmrig/scripts
./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps
make -j$(nproc)
