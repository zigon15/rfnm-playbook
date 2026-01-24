#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Target directory '$BUILD_DIR' does not exist!"
    echo "Did you run ./build.sh script first?"
    exit 1
fi

ABS_OUTPUT_DIR=$(realpath "$BUILD_DIR")

#---- Install LA9310 Firmware ----#
FIRMWARE_DIR="$ABS_OUTPUT_DIR/lib/firmware"
mkdir -p "$FIRMWARE_DIR"

echo "Installing LA9310 firmware to: $FIRMWARE_DIR"

# Copy the LA9310 FreeRTOS firmware binary
cp -v /work/build/la9310-freertos/Demo/CORTEX_M4_NXP_LA9310_GCC/release/la9310.bin "$FIRMWARE_DIR/la9310.bin"

# Set permissions
chmod 644 "$FIRMWARE_DIR/la9310.bin"

echo "Done! Firmware installed to: $FIRMWARE_DIR/la9310.bin"