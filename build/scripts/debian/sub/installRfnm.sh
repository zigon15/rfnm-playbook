#!/bin/sh
# Installs the RFNM rootfs overlay, LA9310 kernel driver modules, and
# LA9310 FreeRTOS firmware into the final Debian rootfs.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEBIAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR='/work/build/debian'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: $BUILD_DIR not found — run the merge stage first."
    exit 1
fi

# Copy the rfnm rootfs overlay.
RFNM_OVERLAY="$DEBIAN_DIR/rootfs-overlay/rfnm"
if [ ! -d "$RFNM_OVERLAY" ]; then
    echo "Error: $RFNM_OVERLAY not found — is the repo fully cloned?"
    exit 1
fi
echo "Copying rfnm rootfs overlay..."
cp -r "$RFNM_OVERLAY/"* "$BUILD_DIR/"
echo "[SUMMARY] overlay:rfnm:copied"

# Install LA9310 kernel driver modules.
LA9310_DRIVER_DIR='/work/build/la9310-driver/kernel_driver'
MODULE_DIR="$BUILD_DIR/rfnm/kernel"
mkdir -p "$MODULE_DIR"

if [ ! -d "$LA9310_DRIVER_DIR/la9310rfnm" ] || [ ! -d "$LA9310_DRIVER_DIR/la9310shiva" ]; then
    echo "Error: LA9310 driver not found at $LA9310_DRIVER_DIR — build la9310-driver first."
    exit 1
fi
echo "Installing LA9310 driver modules to $MODULE_DIR..."
cp -v "$LA9310_DRIVER_DIR/la9310rfnm/"*.ko "$MODULE_DIR/"
cp -v "$LA9310_DRIVER_DIR/la9310shiva/"*.ko "$MODULE_DIR/"

# Install LA9310 FreeRTOS firmware.
FREERTOS_BIN='/work/build/la9310-freertos/Demo/CORTEX_M4_NXP_LA9310_GCC/release/la9310.bin'
FIRMWARE_DIR="$BUILD_DIR/lib/firmware"
mkdir -p "$FIRMWARE_DIR"

if [ ! -f "$FREERTOS_BIN" ]; then
    echo "Error: $FREERTOS_BIN not found — build la9310-freertos first."
    exit 1
fi
echo "Installing LA9310 firmware..."
cp -v "$FREERTOS_BIN" "$FIRMWARE_DIR/la9310.bin"
chmod 644 "$FIRMWARE_DIR/la9310.bin"

echo "✓  RFNM LA9310 install complete."