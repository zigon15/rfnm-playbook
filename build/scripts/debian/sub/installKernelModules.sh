#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'
FIRMWARE_SRC='/work/build/firmware/firmware-imx-8.16/firmware'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Target directory '$BUILD_DIR' does not exist!"
    echo "Did you run ./build.sh script first?"
    exit 1
fi

if [ ! -d "$FIRMWARE_SRC" ]; then
    echo "Error: Firmware source directory '$FIRMWARE_SRC' does not exist!"
    echo "Did you extract/download the firmware-imx package?"
    exit 1
fi

ABS_OUTPUT_DIR=$(realpath "$BUILD_DIR")
FIRMWARE_DEST="$ABS_OUTPUT_DIR/lib/firmware/imx"

#---- Install Kernel Modules to Debian Root Filesystem ----#
echo "Installing modules to: $ABS_OUTPUT_DIR"

cd /work/kernel/
make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$ABS_OUTPUT_DIR" \
    modules_install

#---- Install Firmware to Debian Root Filesystem ----#
echo "Installing firmware to: $FIRMWARE_DEST"

# Create firmware directory if it doesn't exist
mkdir -p "$FIRMWARE_DEST"

# Copy all firmware files recursively, preserving directory structure
echo "Copying firmware files from $FIRMWARE_SRC..."
cp -rv "$FIRMWARE_SRC"/* "$FIRMWARE_DEST/"

echo "Firmware installation complete!"
echo "Installed to: $FIRMWARE_DEST"