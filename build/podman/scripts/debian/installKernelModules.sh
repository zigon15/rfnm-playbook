#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Target directory '$BUILD_DIR' does not exist!"
    echo "Did you run ./build.sh script first?"
    exit 1
fi

ABS_OUTPUT_DIR=$(realpath "$BUILD_DIR")

#---- Install Kernel Modules to Debian Root Filesystem ----#
echo "Installing modules to: $ABS_OUTPUT_DIR"

cd /work/build/imx8mp-kernel/
make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$ABS_OUTPUT_DIR" \
    modules_install