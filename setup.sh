#!/bin/bash

# Auto-Monero  Copyright (C) 2024 teslazonda
# This program comes with ABSOLUTELY NO WARRANTY;
# This is free software, and you are welcome to redistribute it under certain conditions. 

cd ~ 
mkdir Monero-Stuff && cd Monero-Stuff
echo "Update all packages"
sudo dnf -y update
echo "*****************************"

echo "Install Developer Tools group"
echo "*****************************"
sudo dnf -y groupinstall "Development Tools"

echo "Update all packages again"
echo "*****************************"
sudo dnf -y update

echo "Install dependencies for Monero node"
# These are subject to change

sudo dnf -y install git gcc-c++ boost-devel miniupnpc-devel graphviz \
  doxygen libunwind-devel libunwind jsoncpp-devel libcurl-devel \
  openssl-devel pkgconfig libconfig-devel libevent-devel \
  libtool cmake perl

# Install XMRig dependencies
sudo dnf install -y git make cmake gcc gcc-c++ libstdc++-static automake libtool autoconf
# Get XMRig soure code
git clone https://github.com/xmrig/xmrig.git

mkdir xmrig/build

# Replace the 1% donation with 0
cd xmrig/src && sed -i 's/1/0/g' donate.h && cd ../../

# Build dependencies
cd xmrig/scripts && ./build_deps.sh && cd ../build

cmake .. -DXMRIG_DEPS=scripts/deps

echo "making XMRig"

make

echo "Completed XMRig build"

