#!/bin/sh
# Stage 7 — kernel-modules
# Installs compiled kernel modules and NXP i.MX firmware into the final rootfs.
# Requires the kernel to have been built at /work/build/imx8mp-kernel/.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

FIRMWARE_SRC='/work/build/firmware/firmware-imx-8.16/firmware'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: $BUILD_DIR not found — run the merge stage first."
    exit 1
fi

if [ ! -d '/work/build/imx8mp-kernel' ]; then
    echo "Error: /work/build/imx8mp-kernel not found — build the kernel first."
    exit 1
fi

echo "Installing kernel modules to $BUILD_DIR..."
cd /work/build/imx8mp-kernel/
make \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    INSTALL_MOD_PATH="$BUILD_DIR" \
    modules_install

if [ ! -d "$FIRMWARE_SRC" ]; then
    echo "Error: $FIRMWARE_SRC not found — run the repos stage (getFirmware.sh) first."
    exit 1
fi

FIRMWARE_DEST="$BUILD_DIR/lib/firmware/imx"
echo "Installing NXP firmware to $FIRMWARE_DEST..."
mkdir -p "$FIRMWARE_DEST"
cp -r "$FIRMWARE_SRC/"* "$FIRMWARE_DEST/"

echo "✓  Kernel modules installed."
