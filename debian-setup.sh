cd ~ 
echo "Create Monero-Stuff directory"
mkdir Monero-Stuff && cd Monero-Stuff

echo "Update all packages"
sudo apt update && sudo apt upgrade -y

echo "Install XMRig dependencies"
sudo apt install git build-essential cmake automake libtool autoconf

# XMRig setup
git clone https://github.com/xmrig/xmrig.git
# Replace 1% donation with 0%
cd xmrig/src && sed -i 's/1/0/g' donate.h && cd ../../

mkdir xmrig/build && cd xmrig/scripts
./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps
make -j$(nproc)
