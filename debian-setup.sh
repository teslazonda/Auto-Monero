#!/usr/bin/env bash

# Auto-Monero Copyright (C) 2024 teslazonda
# This program comes with ABSOLUTELY NO WARRANTY;
# This is free software, and you are welcome to redistribute it under certain conditions.
#
# Options (environment variables):
#   WORKDIR        where to build            (default: ~/Monero-Stuff)
#   XMRIG_REF      git tag/branch to build   (default: latest vX.Y.Z release tag)
#   DONATE_LEVEL   dev donation percent      (default: 0, as in the original)
#   RUN_UPGRADE    1 = apt upgrade first     (default: 1)
#
# Example: XMRIG_REF=v6.21.0 DONATE_LEVEL=1 ./debian-setup.sh

set -euo pipefail

WORKDIR="${WORKDIR:-$HOME/Monero-Stuff}"
XMRIG_REPO="https://github.com/xmrig/xmrig.git"
XMRIG_REF="${XMRIG_REF:-}"
DONATE_LEVEL="${DONATE_LEVEL:-0}"
RUN_UPGRADE="${RUN_UPGRADE:-1}"

log()  { printf '\n==> %s\n' "$*"; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }

# --- Sanity checks -----------------------------------------------------------
[[ "$DONATE_LEVEL" =~ ^[0-9]+$ ]] || die "DONATE_LEVEL must be a non-negative integer"
command -v apt-get >/dev/null || die "This script needs a Debian-based system (apt-get not found)"

if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    command -v sudo >/dev/null || die "Run as root or install sudo"
    SUDO="sudo"
fi

# --- Packages ----------------------------------------------------------------
log "Updating package lists"
$SUDO apt-get update

if [[ "$RUN_UPGRADE" == "1" ]]; then
    log "Upgrading installed packages"
    $SUDO apt-get upgrade -y
fi

log "Installing build dependencies"
$SUDO apt-get install -y \
    git build-essential cmake automake libtool autoconf \
    ca-certificates curl wget

# --- Fetch source ------------------------------------------------------------
log "Preparing $WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [[ -d xmrig/.git ]]; then
    log "Updating existing XMRig checkout"
    git -C xmrig fetch --tags --force origin
else
    log "Cloning XMRig"
    git clone "$XMRIG_REPO" xmrig
fi

cd xmrig

if [[ -z "$XMRIG_REF" ]]; then
    XMRIG_REF="$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed -n '1p')"
    [[ -n "$XMRIG_REF" ]] || die "Could not determine latest XMRig release tag"
fi

log "Checking out $XMRIG_REF"
git checkout --force "$XMRIG_REF"
SRC_DIR="$PWD"

# --- Donation level ----------------------------------------------------------
# Only touch the two donate-level constants. (The original `sed 's/1/0/g'`
# rewrote every "1" in the file, including comments and years.)
log "Setting donate level to ${DONATE_LEVEL}%"
sed -i -E \
    -e "s/(kDefaultDonateLevel[[:space:]]*=[[:space:]]*)[0-9]+/\1${DONATE_LEVEL}/" \
    -e "s/(kMinimumDonateLevel[[:space:]]*=[[:space:]]*)[0-9]+/\1${DONATE_LEVEL}/" \
    src/donate.h
grep -E 'k(Default|Minimum)DonateLevel' src/donate.h

# --- Build -------------------------------------------------------------------
log "Building bundled dependencies"
(cd scripts && ./build_deps.sh)

log "Configuring and compiling"
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DXMRIG_DEPS="$SRC_DIR/scripts/deps"
make -j"$(nproc)"

log "Done. Binary: $SRC_DIR/build/xmrig"
