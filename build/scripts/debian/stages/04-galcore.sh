#!/bin/sh
# Stage 04 — galcore
# Downloads the Vivante GPU userspace driver (imx-gpu-viv) and stages it.
#
# Runtime files (libs, demos, tools, etc/) → $GALCORE_STAGE
# Dev files (headers, patched pkg-config)  → $CHROOT_DIR/usr/  (needed by 05-weston.sh)
#
# https://layers.openembedded.org/layerindex/recipe/402093/
set -e
. "$(dirname "$0")/common.sh"

GPU_VIV_VERSION="6.4.11.p2.12"
GPU_VIV_BIN="imx-gpu-viv-${GPU_VIV_VERSION}-aarch64-4402ac2.bin"
GPU_VIV_URL="https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/${GPU_VIV_BIN}"
GPU_VIV_CACHE="/work/build/firmware/${GPU_VIV_BIN}"

# ── Download ──────────────────────────────────────────────────────────────────
if [ ! -f "$GPU_VIV_CACHE" ]; then
    echo "[04-galcore] Downloading imx-gpu-viv ${GPU_VIV_VERSION}..."
    mkdir -p /work/build/firmware
    wget -O "$GPU_VIV_CACHE" "$GPU_VIV_URL"
fi

# ── Unpack (cached) ───────────────────────────────────────────────────────────
UNPACK_DIR="/work/build/firmware/imx-gpu-viv-${GPU_VIV_VERSION}-aarch64-unpack"
if [ ! -d "$UNPACK_DIR" ]; then
    echo "[04-galcore] Unpacking ${GPU_VIV_BIN}..."
    mkdir -p "$UNPACK_DIR"
    cd "$UNPACK_DIR"
    chmod +x "$GPU_VIV_CACHE"
    "$GPU_VIV_CACHE" --auto-accept
fi

VIV_SRC=$(find "$UNPACK_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)
if [ -z "$VIV_SRC" ]; then
    echo "Error: could not find unpacked vivante directory in $UNPACK_DIR"
    exit 1
fi

echo "[04-galcore] Installing Vivante GPU driver from ${VIV_SRC}..."

GPU_CORE="${VIV_SRC}/gpu-core"

# ── Stage runtime files → $GALCORE_STAGE ─────────────────────────────────────
STAGE_LIBDIR="$GALCORE_STAGE/usr/lib/aarch64-linux-gnu"
mkdir -p "$STAGE_LIBDIR"

# Common libs (non-display-backend)
cp -v "$GPU_CORE/usr/lib"/lib*.so* "$STAGE_LIBDIR/" 2>/dev/null || true

# Wayland-specific EGL/GLES/Vulkan/GAL libs
cp -v "$GPU_CORE/usr/lib/wayland"/lib*.so* "$STAGE_LIBDIR/"

# SoC-specific NN libs for iMX8MP
cp -v "$GPU_CORE/usr/lib/mx8mp"/lib*.so* "$STAGE_LIBDIR/"

# etc (Vulkan ICD, OpenCL config)
cp -a "$GPU_CORE/etc" "$GALCORE_STAGE/"

# udev rule
mkdir -p "$GALCORE_STAGE/etc/udev/rules.d"
echo 'KERNEL=="galcore", MODE="0660", GROUP="video"' \
    > "$GALCORE_STAGE/etc/udev/rules.d/10-imx.rules"

# Samples/demos
GPU_DEMOS="${VIV_SRC}/gpu-demos"
[ -d "$GPU_DEMOS/opt" ] && cp -a "$GPU_DEMOS/opt" "$GALCORE_STAGE/"

# gmem-info tool
GPU_TOOLS="${VIV_SRC}/gpu-tools"
[ -d "$GPU_TOOLS/gmem-info/usr" ] && cp -a "$GPU_TOOLS/gmem-info/usr" "$GALCORE_STAGE/"

# ── Install dev files → $CHROOT_DIR (needed to compile weston) ───────────────
CHROOT_LIBDIR="$CHROOT_DIR/usr/lib/aarch64-linux-gnu"
mkdir -p "$CHROOT_LIBDIR"

# Copy the same runtime libs into the chroot so pkg-config linkage works
cp -v "$GPU_CORE/usr/lib"/lib*.so* "$CHROOT_LIBDIR/" 2>/dev/null || true
cp -v "$GPU_CORE/usr/lib/wayland"/lib*.so* "$CHROOT_LIBDIR/"
cp -v "$GPU_CORE/usr/lib/mx8mp"/lib*.so* "$CHROOT_LIBDIR/"

# Headers
cp -a "$GPU_CORE/usr/include" "$CHROOT_DIR/usr/"

# pkg-config files — patch libdir to the multiarch path so meson finds them
PKGCONFIG_DIR="$CHROOT_DIR/usr/lib/aarch64-linux-gnu/pkgconfig"
mkdir -p "$PKGCONFIG_DIR"
for pc in "$GPU_CORE/usr/lib/pkgconfig/"*.pc; do
    sed 's|^libdir=/usr/lib$|libdir=/usr/lib/aarch64-linux-gnu|' \
        "$pc" > "$PKGCONFIG_DIR/$(basename "$pc")"
done

echo "[04-galcore] Vivante GPU driver ${GPU_VIV_VERSION} staged."
echo "  Runtime → $GALCORE_STAGE"
echo "  Dev     → $CHROOT_DIR/usr/{include,lib/aarch64-linux-gnu/pkgconfig}"
