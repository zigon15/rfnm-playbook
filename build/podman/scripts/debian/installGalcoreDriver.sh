#!/bin/sh
# Downloads and installs the Vivante GPU userspace driver (imx-gpu-viv)
# into the rootfs at $BUILD_DIR.
#
# Usage: BUILD_DIR=/path/to/rootfs ./installGalcoreDriver.sh

set -e

BUILD_DIR='/work/build/debian'

GPU_VIV_VERSION="6.4.11.p2.12"
GPU_VIV_BIN="imx-gpu-viv-${GPU_VIV_VERSION}-aarch64-4402ac2.bin"
GPU_VIV_URL="https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/${GPU_VIV_BIN}"
GPU_VIV_CACHE="/work/build/firmware/${GPU_VIV_BIN}"

# Download if not cached
if [ ! -f "$GPU_VIV_CACHE" ]; then
    echo "Downloading imx-gpu-viv ${GPU_VIV_VERSION}..."
    mkdir -p /work/build/firmware
    wget -O "$GPU_VIV_CACHE" "$GPU_VIV_URL"
fi

# Unpack to temp dir (cached alongside the bin)
UNPACK_DIR="/work/build/firmware/imx-gpu-viv-${GPU_VIV_VERSION}-aarch64-unpack"
if [ ! -d "$UNPACK_DIR" ]; then
    mkdir -p "$UNPACK_DIR"
    cd "$UNPACK_DIR"
    chmod +x "$GPU_VIV_CACHE"
    "$GPU_VIV_CACHE" --auto-accept
fi

# The self-extracting bin unpacks to a versioned subdirectory
VIV_SRC=$(find "$UNPACK_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)
if [ -z "$VIV_SRC" ]; then
    echo "Error: could not find unpacked vivante directory"
    exit 1
fi

echo "Installing Vivante GPU driver from ${VIV_SRC}..."

GPU_CORE="${VIV_SRC}/gpu-core"
LIBDIR="$BUILD_DIR/usr/lib/aarch64-linux-gnu"
mkdir -p "$LIBDIR"

# Common libs (non-display-backend) from usr/lib/
cp -v "$GPU_CORE/usr/lib"/lib*.so* "$LIBDIR/" 2>/dev/null || true

# Wayland-specific EGL/GLES/Vulkan/GAL libs
cp -v "$GPU_CORE/usr/lib/wayland"/lib*.so* "$LIBDIR/"

# SoC-specific NN libs for iMX8MP
cp -v "$GPU_CORE/usr/lib/mx8mp"/lib*.so* "$LIBDIR/"

# Headers
cp -rv "$GPU_CORE/usr/include" "$BUILD_DIR/usr/"

# etc (Vulkan ICD, OpenCL config)
cp -rv "$GPU_CORE/etc" "$BUILD_DIR/"

# udev rule: give video group access to /dev/galcore
mkdir -p "$BUILD_DIR/etc/udev/rules.d"
echo 'KERNEL=="galcore", MODE="0660", GROUP="video"' > "$BUILD_DIR/etc/udev/rules.d/10-imx.rules"

# Samples/demos
GPU_DEMOS="${VIV_SRC}/gpu-demos"
[ -d "$GPU_DEMOS/opt" ] && cp -rv "$GPU_DEMOS/opt" "$BUILD_DIR/"

# gmem-info tool
GPU_TOOLS="${VIV_SRC}/gpu-tools"
[ -d "$GPU_TOOLS/gmem-info/usr" ] && cp -rv "$GPU_TOOLS/gmem-info/usr" "$BUILD_DIR/"

echo "Vivante GPU driver ${GPU_VIV_VERSION} installed."
