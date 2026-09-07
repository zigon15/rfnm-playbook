#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'
FIRMWARE_SRC='/work/build/firmware/firmware-imx-8.31-4fa5b46/firmware'

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
FIRMWARE_ROOT="$ABS_OUTPUT_DIR/lib/firmware"
FIRMWARE_IMX_DEST="$FIRMWARE_ROOT/imx"

#---- Install Kernel Modules to Debian Root Filesystem ----#
echo "Installing modules to: $ABS_OUTPUT_DIR"

cd /work/kernel/
make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$ABS_OUTPUT_DIR" \
    modules_install

#---- Install Firmware to Debian Root Filesystem ----#
echo "Installing firmware to: $FIRMWARE_ROOT"

# Create firmware directory if it doesn't exist
mkdir -p "$FIRMWARE_IMX_DEST"

# Copy all firmware files recursively, preserving directory structure
echo "Copying firmware files from $FIRMWARE_SRC..."
cp -rv "$FIRMWARE_SRC"/* "$FIRMWARE_IMX_DEST/"

# Match the firmware-imx 8.31 Yocto layout used by NXP's 6.18 branches.
install -m 0644 "$FIRMWARE_SRC/hdmi/cadence/hdmitxfw.bin" "$FIRMWARE_ROOT/"
install -m 0644 "$FIRMWARE_SRC/hdmi/cadence/hdmirxfw.bin" "$FIRMWARE_ROOT/"
install -m 0644 "$FIRMWARE_SRC/hdmi/cadence/dpfw.bin" "$FIRMWARE_ROOT/"

mkdir -p "$FIRMWARE_ROOT/vpu" "$FIRMWARE_ROOT/amphion/vpu"
install -m 0644 "$FIRMWARE_SRC"/vpu/vpu_fw_imx*.bin "$FIRMWARE_ROOT/vpu/"
mv "$FIRMWARE_ROOT"/vpu/vpu_fw_imx8*.bin "$FIRMWARE_ROOT/amphion/vpu/"

echo "Firmware installation complete!"
echo "Installed to: $FIRMWARE_ROOT"
