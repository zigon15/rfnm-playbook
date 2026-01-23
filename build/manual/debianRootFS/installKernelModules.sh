#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='../../../build'
TARGET_FOLDER="$BUILD_DIR/rfnm-debian-rootfs"

if [ ! -d "$TARGET_FOLDER" ]; then
    echo "Error: Target directory '$TARGET_FOLDER' does not exist!"
    echo "Did you run ./buildDebian.sh script first?"
    exit 1
fi

ABS_OUTPUT_DIR=$(realpath "$TARGET_FOLDER")

#---- Install Kernel Modules to Debian Root Filesystem ----#
echo "Installing modules to: $ABS_OUTPUT_DIR"

cd ../../../imx8mp-kernel/
sudo make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$ABS_OUTPUT_DIR" \
    modules_install