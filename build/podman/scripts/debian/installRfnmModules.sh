#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Target directory '$BUILD_DIR' does not exist!"
    echo "Did you run ./build.sh script first?"
    exit 1
fi

ABS_OUTPUT_DIR=$(realpath "$BUILD_DIR")

#---- Get Kernel Version ----#
KERNEL_VERSION=$(cd /work/build/imx8mp-kernel && make -s kernelrelease)
echo "Kernel version: $KERNEL_VERSION"

#---- Create Module Directory ----#
MODULE_DIR="$ABS_OUTPUT_DIR/lib/modules/$KERNEL_VERSION/extra"
mkdir -p "$MODULE_DIR"

#---- Install RFNM Driver Modules to Debian Root Filesystem ----#
echo "Installing RFNM LA9310 driver modules to: $ABS_OUTPUT_DIR"

cp -v /work/build/la9310-driver/kernel_driver/la9310rfnm/*.ko "$MODULE_DIR/"

#---- Update Module Dependencies ----#
echo "Updating module dependencies..."
depmod -b "$ABS_OUTPUT_DIR" "$KERNEL_VERSION"

echo "Done! Modules installed to: $MODULE_DIR"