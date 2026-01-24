#!/bin/bash

# Color definitions
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${CYAN}--- $1 ---${NC}"
}

# Get the repositories
echo_step "Getting the repositories"
cd /work/scripts/git
./cloneRepos.sh
./checkoutGoodCommits.sh
./getFirmware.sh

# Check firmware exists
if [ ! -d "/work/build/firmware/firmware-imx-8.16/" ]; then
    echo "✗ FAIL: Firmware base directory not found: /work/build/firmware/firmware-imx-8.16/"
    exit 1
fi

set -e

# Build U-Boot
echo_step "Building U-Boot"
cd /work/scripts/uboot

./buildATF.sh
./build.sh

# Build the Linux Kernel
echo_step "Building the Linux Kernel"
cd /work/scripts/kernel
./build.sh

# Build the Debian Root Filesystem
echo_step "Building the Debian Root Filesystem"
cd /work/scripts/debian
./build.sh
./installKernelModules.sh
./installRfnmModules.sh
./installFirmware.sh
