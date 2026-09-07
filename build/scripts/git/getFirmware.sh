#!/bin/sh

mkdir -p /work/build/firmware
cd /work/build/firmware

FIRMWARE_IMX_VERSION=8.31
FIRMWARE_IMX_REV=4fa5b46
FIRMWARE_IMX_BUNDLE="firmware-imx-${FIRMWARE_IMX_VERSION}-${FIRMWARE_IMX_REV}.bin"

wget -O "$FIRMWARE_IMX_BUNDLE" "https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/$FIRMWARE_IMX_BUNDLE"
chmod +x "$FIRMWARE_IMX_BUNDLE"
./"$FIRMWARE_IMX_BUNDLE" --auto-accept
