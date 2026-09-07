#!/bin/sh
# Stage 7 — kernel-modules
# Installs compiled kernel modules and NXP i.MX firmware into the final rootfs.
# Requires the kernel to have been built at /work/kernel.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

FIRMWARE_SRC='/work/build/firmware/firmware-imx-8.31-4fa5b46/firmware'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: $BUILD_DIR not found — run the merge stage first."
    exit 1
fi

if [ ! -d '/work/kernel' ]; then
    echo "Error: /work/kernel not found — build the kernel first."
    exit 1
fi

echo "Installing kernel modules to $BUILD_DIR..."
cd /work/kernel/
make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$BUILD_DIR" \
    modules_install

if [ ! -d "$FIRMWARE_SRC" ]; then
    echo "Error: $FIRMWARE_SRC not found — run the repos stage (getFirmware.sh) first."
    exit 1
fi

FIRMWARE_ROOT="$BUILD_DIR/lib/firmware"
FIRMWARE_IMX_DEST="$FIRMWARE_ROOT/imx"
echo "Installing NXP firmware to $FIRMWARE_ROOT..."
mkdir -p "$FIRMWARE_IMX_DEST"
cp -r "$FIRMWARE_SRC/"* "$FIRMWARE_IMX_DEST/"

# Match the firmware-imx 8.31 Yocto layout used by NXP's 6.18 branches.
install -m 0644 "$FIRMWARE_SRC/hdmi/cadence/hdmitxfw.bin" "$FIRMWARE_ROOT/"
install -m 0644 "$FIRMWARE_SRC/hdmi/cadence/hdmirxfw.bin" "$FIRMWARE_ROOT/"
install -m 0644 "$FIRMWARE_SRC/hdmi/cadence/dpfw.bin" "$FIRMWARE_ROOT/"

mkdir -p "$FIRMWARE_ROOT/vpu" "$FIRMWARE_ROOT/amphion/vpu"
install -m 0644 "$FIRMWARE_SRC"/vpu/vpu_fw_imx*.bin "$FIRMWARE_ROOT/vpu/"
mv "$FIRMWARE_ROOT"/vpu/vpu_fw_imx8*.bin "$FIRMWARE_ROOT/amphion/vpu/"

echo "✓  Kernel modules installed."
