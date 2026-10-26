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

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script targets macOS." >&2; exit 1; }

echo "Create Monero-Stuff directory"
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"
echo "Working directory: $PWD"

# Install Homebrew only if it is missing (CI runners already have it)
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Put brew on PATH for this session (Apple Silicon vs Intel)
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Do not upgrade unrelated, already-installed formulae. A blanket
# 'brew upgrade' re-links things like python and fails with
# "These files were overwritten during the brew link step".
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

echo "Update Homebrew"
brew update

echo "Install XMRig dependencies"
# Pin openssl@3: the unversioned 'openssl' formula now points to OpenSSL 4,
# which XMRig's TlsGen.cpp does not compile against yet.
brew install cmake wget automake libtool autoconf libuv openssl@3 hwloc

echo "Get XMRig source code"
if [[ -d "$XMRIG_DIR/.git" ]]; then
    # Re-run safe: discard our earlier donate.h edit, then update
    git -C "$XMRIG_DIR" checkout -- src/donate.h
    git -C "$XMRIG_DIR" pull --ff-only
else
    git clone https://github.com/xmrig/xmrig.git "$XMRIG_DIR"
fi
mkdir -p "$XMRIG_DIR/build"

echo "Make xmrig donation 0%"
# Only touch the two donate-level constants. '-i.bak' works with both
# BSD sed (macOS) and GNU sed; plain 'sed -i' fails on macOS.
sed -i.bak -E 's/(k(Default|Minimum)DonateLevel *= *)1;/\10;/' "$XMRIG_DIR/src/donate.h"
rm -f "$XMRIG_DIR/src/donate.h.bak"
grep -q 'kMinimumDonateLevel *= *0' "$XMRIG_DIR/src/donate.h" \
    || { echo "donate.h patch did not apply; upstream may have changed" >&2; exit 1; }

echo "Building static hwloc"
cd "$XMRIG_DIR/scripts"
./build.hwloc.sh

echo "Configuring XMRig"
cd "$XMRIG_DIR/build"
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DOPENSSL_ROOT_DIR="$(brew --prefix openssl@3)" \
    -DHWLOC_INCLUDE_DIR="$XMRIG_DIR/scripts/deps/include" \
    -DHWLOC_LIBRARY="$XMRIG_DIR/scripts/deps/lib/libhwloc.a"

echo "making XMRig"
make -j"$(sysctl -n hw.logicalcpu)"

echo "XMRig build completed successfully: $XMRIG_DIR/build/xmrig"

