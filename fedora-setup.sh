#!/bin/bash

# Auto-Monero  Copyright (C) 2024 teslazonda
# This program comes with ABSOLUTELY NO WARRANTY;
# This is free software, and you are welcome to redistribute it under certain conditions. 

set -euo pipefail  # Exit on error, undefined vars, pipe failures
# Configuration
WORK_DIR="$HOME/Monero-Stuff"
XMRIG_DIR="$WORK_DIR/xmrig"

# Exit handler
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Verify prerequisites
command -v sudo &> /dev/null || { echo "sudo required"; exit 1; }

# Create working directory
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"
echo "Working directory: $PWD"

echo "Update all packages"
sudo dnf -y upgrade
echo "*****************************"

echo "Install Developer Tools"
echo "*****************************"
sudo dnf -y group install development-tools c-development

echo "Update all packages again"
echo "*****************************"
sudo dnf -y upgrade
echo "*****************************"

echo "Install dependencies for Monero node"
# These are subject to change
# Additional packages outside of dependencies added here for convenience

sudo dnf -y install git gcc-c++ boost-devel miniupnpc-devel graphviz \
  doxygen libunwind-devel libunwind jsoncpp-devel libcurl-devel \
  openssl-devel pkgconfig libconfig-devel libevent-devel \
  libtool cmake perl vim zsh

# Install XMRig dependencies
sudo dnf install -y git make cmake gcc gcc-c++ libstdc++-static automake libtool autoconf
# Get XMRig soure code
git clone https://github.com/xmrig/xmrig.git

mkdir -p "$XMRIG_DIR/build"

# Remove the 1% default donation
cd $XMRIG_DIR/src && sed -i 's/1/0/g' donate.h && cd ../../

cd "$XMRIG_DIR/scripts" && ./build_deps.sh
cd "$XMRIG_DIR/build"

cmake .. -DXMRIG_DEPS=scripts/deps

echo "making XMRig"

make -j$(nproc)

echo "XMRig build completed successfully."
