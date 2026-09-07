#!/bin/sh
# Stage 03 — vivante (GPU userspace) + Hantro VPU
# Downloads the Vivante GPU userspace driver (imx-gpu-viv) and the Hantro VPU
# userspace driver (imx-vpu-hantro) and stages them.
#
# Note: the galcore.ko kernel module itself is built from the iMX kernel tree
# and installed by 07-kernel-modules.sh; this stage handles userspace only.
#
# Runtime files (libs, demos, tools, etc/) → $GALCORE_STAGE
# Dev files (headers, patched pkg-config)  → $CHROOT_DIR/usr/  (needed by 05-weston.sh)
#
# https://layers.openembedded.org/layerindex/recipe/402093/
# https://layers.openembedded.org/layerindex/recipe/87004/
set -e
. "$(dirname "$0")/common.sh"

GPU_VIV_VERSION="6.4.11.p4.4-aarch64-8626797"
GPU_VIV_BIN="imx-gpu-viv-${GPU_VIV_VERSION}.bin"
GPU_VIV_URL="https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/${GPU_VIV_BIN}"
GPU_VIV_CACHE="/work/build/firmware/${GPU_VIV_BIN}"

HANTRO_VERSION="1.40.0-52c7e45"
HANTRO_BIN="imx-vpu-hantro-${HANTRO_VERSION}.bin"
HANTRO_URL="https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/${HANTRO_BIN}"
HANTRO_CACHE="/work/build/firmware/${HANTRO_BIN}"

# Nuke any partial unpack from a previous crashed run.
rm -rf \
    "$GALCORE_STAGE" \
    "/work/build/firmware/imx-gpu-viv-${GPU_VIV_VERSION}-unpack" \
    "/work/build/firmware/imx-vpu-hantro-${HANTRO_VERSION}-unpack"

# ── Download Vivante GPU driver ───────────────────────────────────────────────
if [ ! -f "$GPU_VIV_CACHE" ]; then
    echo "[03-vivante] Downloading imx-gpu-viv ${GPU_VIV_VERSION}..."
    mkdir -p /work/build/firmware
    wget -O "$GPU_VIV_CACHE" "$GPU_VIV_URL"
fi

# ── Unpack Vivante (cached) ───────────────────────────────────────────────────
GPU_VIV_UNPACK="/work/build/firmware/imx-gpu-viv-${GPU_VIV_VERSION}-unpack"
if [ ! -d "$GPU_VIV_UNPACK" ]; then
    echo "[03-vivante] Unpacking ${GPU_VIV_BIN}..."
    mkdir -p "$GPU_VIV_UNPACK"
    cd "$GPU_VIV_UNPACK"
    chmod +x "$GPU_VIV_CACHE"
    "$GPU_VIV_CACHE" --auto-accept
fi

VIV_SRC=$(find "$GPU_VIV_UNPACK" -maxdepth 1 -mindepth 1 -type d | head -1)
if [ -z "$VIV_SRC" ]; then
    echo "Error: could not find unpacked vivante directory in $GPU_VIV_UNPACK"
    exit 1
fi

echo "[03-vivante] Installing Vivante GPU driver from ${VIV_SRC}..."

GPU_CORE="${VIV_SRC}/gpu-core"
GPU_DEMOS="${VIV_SRC}/gpu-demos"
GPU_TOOLS="${VIV_SRC}/gpu-tools"

# ── Stage Vivante runtime files → $GALCORE_STAGE ─────────────────────────────
STAGE_LIBDIR="$GALCORE_STAGE/usr/lib/aarch64-linux-gnu"
mkdir -p "$STAGE_LIBDIR"
mkdir -p "$GALCORE_STAGE/usr/lib"

# 1) Copy the entire gpu-core/usr/lib tree, preserving symlinks and modes.
cp -a "$GPU_CORE/usr/lib"/. "$GALCORE_STAGE/usr/lib/"

# 2) Promote common libs from /usr/lib to /usr/lib/aarch64-linux-gnu/.
#    Use `find` so symlinks (which `mv lib*.so*` would resolve incorrectly with
#    some shells) are moved as-is.
find "$GALCORE_STAGE/usr/lib" -maxdepth 1 \( -type f -o -type l \) \
    -name 'lib*.so*' -exec mv -t "$STAGE_LIBDIR/" {} +

# 3) Flatten Wayland-backend variants over the common ones (override).
if [ -d "$GALCORE_STAGE/usr/lib/wayland" ]; then
    cp -a "$GALCORE_STAGE/usr/lib/wayland"/. "$STAGE_LIBDIR/"
    rm -rf "$GALCORE_STAGE/usr/lib/wayland"
fi

# 4) Promote the iMX8MP NN binaries (loader needs them on PATH).
if [ -d "$GALCORE_STAGE/usr/lib/mx8mp" ]; then
    cp -a "$GALCORE_STAGE/usr/lib/mx8mp"/. "$STAGE_LIBDIR/"
fi

# 5) Other per-SoC dirs (mx8mn/mx8mq/mx8qm/mx8qxp/mx8ulp) are kept as-is.

# 6) Remove dev-only bits from the runtime stage.
rm -rf "$GALCORE_STAGE/usr/lib/pkgconfig"
mkdir -p "$STAGE_LIBDIR/pkgconfig"
for pc in gbm glesv1_cm glesv2 vg; do
    if [ -f "$GPU_CORE/usr/lib/pkgconfig/${pc}.pc" ]; then
        sed 's|^libdir=/usr/lib$|libdir=/usr/lib/aarch64-linux-gnu|' \
            "$GPU_CORE/usr/lib/pkgconfig/${pc}.pc" > "$STAGE_LIBDIR/pkgconfig/${pc}.pc"
    fi
done
if [ -f "$GPU_CORE/usr/lib/pkgconfig/egl_wayland.pc" ]; then
    sed 's|^libdir=/usr/lib$|libdir=/usr/lib/aarch64-linux-gnu|' \
        "$GPU_CORE/usr/lib/pkgconfig/egl_wayland.pc" > "$STAGE_LIBDIR/pkgconfig/egl.pc"
fi

# 7) etc (Vulkan ICD, OpenCL config) and udev rule.
mkdir -p "$GALCORE_STAGE/etc"
cp -a "$GPU_CORE/etc"/. "$GALCORE_STAGE/etc/"
mkdir -p "$GALCORE_STAGE/etc/udev/rules.d"
echo 'KERNEL=="galcore", MODE="0660", GROUP="video"' \
    > "$GALCORE_STAGE/etc/udev/rules.d/10-imx.rules"

# 8) Samples/demos and gmem_info tool.
[ -d "$GPU_DEMOS/opt" ]           && cp -a "$GPU_DEMOS/opt"           "$GALCORE_STAGE/"
[ -d "$GPU_TOOLS/gmem-info/usr" ] && cp -a "$GPU_TOOLS/gmem-info/usr" "$GALCORE_STAGE/"

# ── Install Vivante dev files → $CHROOT_DIR (needed to compile weston) ───────
CHROOT_LIBDIR="$CHROOT_DIR/usr/lib/aarch64-linux-gnu"
mkdir -p "$CHROOT_LIBDIR"

# Copy the same runtime libs into the chroot so pkg-config linkage works.
# Use cp -a to preserve the SONAME symlink chain.
cp -a "$GPU_CORE/usr/lib"/lib*.so*           "$CHROOT_LIBDIR/" 2>/dev/null || true
cp -a "$GPU_CORE/usr/lib/wayland"/lib*.so*   "$CHROOT_LIBDIR/"
cp -a "$GPU_CORE/usr/lib/mx8mp"/lib*.so*     "$CHROOT_LIBDIR/"

# Headers
cp -a "$GPU_CORE/usr/include" "$CHROOT_DIR/usr/"

# pkg-config files — patch libdir to the multiarch path so meson finds them
PKGCONFIG_DIR="$CHROOT_DIR/usr/lib/aarch64-linux-gnu/pkgconfig"
mkdir -p "$PKGCONFIG_DIR"
for pc in "$GPU_CORE/usr/lib/pkgconfig/"*.pc; do
    sed 's|^libdir=/usr/lib$|libdir=/usr/lib/aarch64-linux-gnu|' \
        "$pc" > "$PKGCONFIG_DIR/$(basename "$pc")"
done

# Match the NXP Yocto Wayland distro behavior: the backend-specific EGL
# pkg-config file becomes egl.pc, so consumers build with WL_EGL_PLATFORM.
if [ -f "$GPU_CORE/usr/lib/pkgconfig/egl_wayland.pc" ]; then
    sed 's|^libdir=/usr/lib$|libdir=/usr/lib/aarch64-linux-gnu|' \
        "$GPU_CORE/usr/lib/pkgconfig/egl_wayland.pc" > "$PKGCONFIG_DIR/egl.pc"
fi

# ── Download Hantro VPU driver ───────────────────────────────────────────────
if [ ! -f "$HANTRO_CACHE" ]; then
    echo "[03-vivante] Downloading imx-vpu-hantro ${HANTRO_VERSION}..."
    mkdir -p /work/build/firmware
    wget -O "$HANTRO_CACHE" "$HANTRO_URL"
fi

# ── Unpack Hantro (cached) ────────────────────────────────────────────────────
HANTRO_UNPACK="/work/build/firmware/imx-vpu-hantro-${HANTRO_VERSION}-unpack"
if [ ! -d "$HANTRO_UNPACK" ]; then
    echo "[03-vivante] Unpacking ${HANTRO_BIN}..."
    mkdir -p "$HANTRO_UNPACK"
    cd "$HANTRO_UNPACK"
    chmod +x "$HANTRO_CACHE"
    "$HANTRO_CACHE" --auto-accept
fi

HANTRO_SRC=$(find "$HANTRO_UNPACK" -maxdepth 1 -mindepth 1 -type d | head -1)
if [ -z "$HANTRO_SRC" ]; then
    echo "Error: could not find unpacked hantro directory in $HANTRO_UNPACK"
    exit 1
fi

echo "[03-vivante] Installing Hantro VPU driver from ${HANTRO_SRC}..."

# Stage Hantro runtime libs (live at /usr/lib/, not /usr/lib/aarch64-linux-gnu/,
# matching the working device extract).
mkdir -p "$GALCORE_STAGE/usr/lib"
if [ -d "$HANTRO_SRC/usr/lib" ]; then
    cp -a "$HANTRO_SRC/usr/lib"/lib*.so* "$GALCORE_STAGE/usr/lib/" 2>/dev/null || true
    cp -a "$HANTRO_SRC/usr/lib"/lib*.so* "$CHROOT_DIR/usr/lib/"    2>/dev/null || true
fi

echo "[03-vivante] Vivante GPU driver ${GPU_VIV_VERSION} + Hantro ${HANTRO_VERSION} staged."
echo "  Runtime → $GALCORE_STAGE"
echo "  Dev     → $CHROOT_DIR/usr/{include,lib/aarch64-linux-gnu/pkgconfig}"
