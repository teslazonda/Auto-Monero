#!/usr/bin/env bash

# Auto-Monero Copyright (C) 2024 teslazonda
# This program comes with ABSOLUTELY NO WARRANTY;
# This is free software, and you are welcome to redistribute it under certain conditions.

set -euo pipefail # Exit on error, undefined vars, pipe failures

# Configuration
WORK_DIR="${WORK_DIR:-$HOME/Monero-Stuff}"
XMRIG_DIR="$WORK_DIR/xmrig"

# Exit handler
trap 'echo "Error on line $LINENO" >&2; exit 1' ERR

# Verify we are on Fedora
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi
if [[ "${ID:-}" != "fedora" ]]; then
    echo "This script targets Fedora (detected: ${PRETTY_NAME:-unknown})." >&2
    exit 1
fi

# Verify prerequisites (works for dnf4 and dnf5; 'dnf' is the command on both)
command -v dnf &> /dev/null || { echo "dnf required" >&2; exit 1; }

SUDO=""
if [[ $EUID -ne 0 ]]; then
    command -v sudo &> /dev/null || { echo "sudo required (or run as root)" >&2; exit 1; }
    SUDO="sudo"
fi

# Create working directory
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"
echo "Working directory: $PWD"

echo "Update all packages"
$SUDO dnf -y upgrade --refresh

echo "*****************************"
echo "Install Developer Tools"
echo "*****************************"
# Group IDs work on both dnf4 and dnf5
$SUDO dnf -y group install development-tools c-development

echo "*****************************"
echo "Install dependencies for Monero node"
# These are subject to change; check the Monero README for the current list.
# Additional packages outside of dependencies added here for convenience.
$SUDO dnf -y install \
    git gcc-c++ boost-devel miniupnpc-devel graphviz \
    doxygen libunwind-devel libunwind jsoncpp-devel libcurl-devel \
    openssl-devel pkgconf-pkg-config libconfig-devel libevent-devel \
    unbound-devel hidapi-devel zeromq-devel libsodium-devel \
    readline-devel expat-devel protobuf-devel protobuf-compiler \
    libtool cmake perl vim zsh

echo "*****************************"
echo "Install XMRig dependencies"
# perl-core: OpenSSL (built by build_deps.sh) needs perl modules such as
#            IPC::Cmd that are not in Fedora's base perl package.
# libstdc++-static: needed for the static build.
$SUDO dnf -y install \
    git make cmake gcc gcc-c++ libstdc++-static \
    automake libtool autoconf perl-core curl wget

echo "*****************************"
echo "Get XMRig source code"
if [[ -d "$XMRIG_DIR/.git" ]]; then
    # Re-run safe: discard our earlier donate.h edit, then update
    git -C "$XMRIG_DIR" checkout -- src/donate.h
    git -C "$XMRIG_DIR" pull --ff-only
else
    git clone https://github.com/xmrig/xmrig.git "$XMRIG_DIR"
fi
mkdir -p "$XMRIG_DIR/build"

# Remove the 1% default donation (only the two donate-level constants)
sed -i -E 's/(k(Default|Minimum)DonateLevel *= *)1;/\10;/' "$XMRIG_DIR/src/donate.h"
grep -q 'kMinimumDonateLevel *= *0' "$XMRIG_DIR/src/donate.h" \
    || { echo "donate.h patch did not apply; upstream may have changed" >&2; exit 1; }

echo "Building XMRig static dependencies"
cd "$XMRIG_DIR/scripts"
./build_deps.sh

cd "$XMRIG_DIR/build"
cmake .. -DCMAKE_BUILD_TYPE=Release -DXMRIG_DEPS="$XMRIG_DIR/scripts/deps"

echo "making XMRig"
make -j"$(nproc)"

echo "XMRig build completed successfully: $XMRIG_DIR/build/xmrig"
