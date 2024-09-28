# Auto-Monero

A collection of shell scripts for automating the installation of Monero-related software.

Scripts in this repository will install the following software:  

* [XMRig](https://xmrig.com)
* XMRig dependencies

## Installation

Download an install Auto-Monero scripts with the following commands:


`git clone https://github.com/teslazonda/Auto-Monero.git`  
`cd Auto-Monero`

Run the script that matches your local operating system.

For example, on Fedora linux run the following commands within the `Auto-Monero` directory.
```bash
chmod +x ./fedora-setup.sh
./fedora-setup.sh
```

### Notes
* You will prompted to enter your `sudo` password several times while the script is running.  
* Xmrig will be [built from source](https://xmrig.com/docs/miner/build). Compile times may vary.
