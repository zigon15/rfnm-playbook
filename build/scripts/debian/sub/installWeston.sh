#!/bin/sh
# Builds and installs weston-imx from source into the rootfs at $BUILD_DIR.
# Requires the Vivante GPU driver (with pkg-config files) to be installed first
# (installGalcoreDriver.sh).
#
# The build runs inside the arm64 chroot under QEMU emulation so all packages
# resolve natively — no cross-compilation toolchain required.
# https://layers.openembedded.org/layerindex/recipe/402089/

set -e

BUILD_DIR='/work/build/debian'
DEBUG_LOG_PATH='/home/simon/dev/rfnm/rfnm-playbook/.cursor/debug-cbba97.log'
DEBUG_RUN_ID="${DEBUG_RUN_ID:-pre-fix}"

debug_log() {
    hypothesis_id="$1"
    location="$2"
    message="$3"
    data="$4"
    mkdir -p "$(dirname "$DEBUG_LOG_PATH")"
    ts="$(date +%s%3N 2>/dev/null || echo 0)"
    printf '{"sessionId":"cbba97","runId":"%s","hypothesisId":"%s","location":"%s","message":"%s","data":{"details":"%s"},"timestamp":%s}\n' \
        "$DEBUG_RUN_ID" "$hypothesis_id" "$location" "$message" "$data" "$ts" >> "$DEBUG_LOG_PATH"
}

# Ensure the Debian rootfs has been bootstrapped before attempting a chroot build
if [ ! -x "$BUILD_DIR/bin/sh" ]; then
    echo "Error: Debian rootfs at $BUILD_DIR is not ready (missing $BUILD_DIR/bin/sh)."
    echo "Run buildWeston_GalcoreGPU.sh to set up the rootfs first."
    exit 1
fi

WESTON_REPO='https://github.com/nxp-imx/weston-imx.git'
WESTON_BRANCH='weston-imx-12.0.5'
WESTON_SRC='/work/build/weston-imx-src'

WP_IMX_REPO='https://github.com/nxp-imx/wayland-protocols-imx.git'
WP_IMX_TAG='lf-6.6.36-2.1.0'
WP_IMX_SRC='/work/build/wayland-protocols-imx-src'

# ── Clone on x86 host (fast native git, cached) ───────────────────────────────
if [ ! -d "$WESTON_SRC/.git" ]; then
    echo "Cloning weston-imx ${WESTON_BRANCH}..."
    git clone --branch "$WESTON_BRANCH" --depth 1 "$WESTON_REPO" "$WESTON_SRC"
else
    echo "Using cached weston-imx source at $WESTON_SRC"
fi

if [ ! -d "$WP_IMX_SRC/.git" ]; then
    echo "Cloning wayland-protocols-imx ${WP_IMX_TAG}..."
    git clone --branch "$WP_IMX_TAG" --depth 1 "$WP_IMX_REPO" "$WP_IMX_SRC"
else
    echo "Using cached wayland-protocols-imx source at $WP_IMX_SRC"
fi

# ── Stage source inside chroot ────────────────────────────────────────────────
echo "Staging sources inside rootfs..."
mkdir -p "$BUILD_DIR/tmp"
rm -rf "$BUILD_DIR/tmp/weston-imx-src"
cp -r "$WESTON_SRC" "$BUILD_DIR/tmp/weston-imx-src"
rm -rf "$BUILD_DIR/tmp/wayland-protocols-imx-src"
cp -r "$WP_IMX_SRC" "$BUILD_DIR/tmp/wayland-protocols-imx-src"

# ── Install build dependencies inside arm64 chroot ───────────────────────────
echo "Installing weston-imx build dependencies inside arm64 chroot (QEMU)..."
chroot "$BUILD_DIR" /bin/sh <<'CHROOT_DEPS'
set -e
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 8.8.8.8" > /etc/resolv.conf
apt-get update
apt-get install -y \
    meson \
    ninja-build \
    pkg-config \
    libdrm-dev \
    libpixman-1-dev \
    libxkbcommon-dev \
    libwayland-dev \
    libwayland-bin \
    wayland-protocols \
    libinput-dev \
    libseat-dev \
    libpam0g-dev \
    libsystemd-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libpng-dev \
    libjpeg-dev \
    libcairo2-dev \
    libwebp-dev \
    libpango1.0-dev \
    libdisplay-info-dev \
    glslang-tools
CHROOT_DEPS

# ── Patch libdrm headers (after libdrm-dev install) ───────────────────────────
# Debian's libdrm-dev is missing NXP-specific DRM format modifiers
# (DRM_FORMAT_MOD_AMPHION_TILED, DRM_FORMAT_MOD_VIVANTE_SUPER_TILED_FC).
# Must run after apt-get above, which would otherwise overwrite this file.
NXP_FOURCC='/work/build/imx8mp-kernel/include/uapi/drm/drm_fourcc.h'
if [ -f "$NXP_FOURCC" ]; then
    echo "Patching chroot libdrm headers with NXP kernel version..."
    cp "$NXP_FOURCC" "$BUILD_DIR/usr/include/libdrm/drm_fourcc.h"
else
    echo "Warning: NXP kernel not found at $NXP_FOURCC; build may fail with missing DRM modifier constants."
fi

# ── Build and install inside arm64 chroot ─────────────────────────────────────
echo "Building weston-imx inside arm64 chroot (QEMU)..."
chroot "$BUILD_DIR" /bin/sh <<'CHROOT'
set -e
export DEBIAN_FRONTEND=noninteractive

# Build and install wayland-protocols-imx (NXP fork) to provide the
# hdr10-metadata-unstable-v1.xml protocol required by weston-imx.
# This overwrites the pkgdatadir used by Debian's wayland-protocols package.
meson setup /tmp/wp-imx-build /tmp/wayland-protocols-imx-src --prefix=/usr
ninja -C /tmp/wp-imx-build install
rm -rf /tmp/wayland-protocols-imx-src /tmp/wp-imx-build

# Configure — Vivante EGL/GLES/GBM .pc files are in the default pkg-config
# search path (/usr/lib/aarch64-linux-gnu/pkgconfig) so no PKG_CONFIG_PATH needed.
# Do NOT install libegl-dev / libgles2-dev / libgbm-dev — Vivante .pc files
# take priority and Mesa's would conflict.
rm -rf /tmp/weston-imx-build
meson setup /tmp/weston-imx-build /tmp/weston-imx-src \
    --prefix=/usr \
    --buildtype=release \
    -Dbackend-drm=true \
    -Dbackend-wayland=false \
    -Dbackend-x11=false \
    -Dbackend-headless=false \
    -Dbackend-pipewire=false \
    -Dbackend-rdp=false \
    -Dbackend-vnc=false \
    -Dbackend-drm-screencast-vaapi=false \
    -Dscreenshare=false \
    -Drenderer-gl=true \
    -Drenderer-g2d=false \
    -Dxwayland=false \
    -Dremoting=false \
    -Dpipewire=false \
    -Dcolor-management-lcms=false \
    -Ddeprecated-color-management-static=false \
    -Ddeprecated-color-management-colord=false \
    -Dsimple-clients=[] \
    -Ddemo-clients=false \
    -Dtest-junit-xml=false \
    -Ddoc=false \
    -Dtools=terminal

ninja -C /tmp/weston-imx-build
ninja -C /tmp/weston-imx-build install

# Clean up build artifacts
rm -rf /tmp/weston-imx-src /tmp/weston-imx-build

# Remove build-only packages to keep rootfs lean
# apt-get purge -y \
#     meson ninja-build pkg-config \
#     libdrm-dev libpixman-1-dev libxkbcommon-dev \
#     libwayland-dev wayland-protocols \
#     libinput-dev libseat-dev libpam0g-dev \
#     libsystemd-dev libdbus-1-dev libglib2.0-dev \
#     libpng-dev libjpeg-dev libcairo2-dev libwebp-dev libpango1.0-dev libdisplay-info-dev glslang-tools 2>/dev/null || true
# apt-get autoremove -y
# apt-get clean

# Restore the systemd resolv.conf symlink for the final system
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
CHROOT

# region agent log H4
if [ -x "$BUILD_DIR/usr/bin/weston" ] && [ -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libweston-13/drm-backend.so" ]; then
    debug_log "H4_weston_install" "installWeston.sh:169" "weston binary and DRM backend installed" "rootfs=${BUILD_DIR}"
else
    debug_log "H4_weston_install" "installWeston.sh:171" "weston install incomplete" "rootfs=${BUILD_DIR}"
fi
# endregion

# region agent log H5
if [ -e "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libEGL_mesa.so.0.0.0" ] || [ -e "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2_mesa.so.2.0.0" ]; then
    debug_log "H5_mesa_mix" "installWeston.sh:177" "Mesa GL artifacts present in rootfs" "rootfs=${BUILD_DIR}"
else
    debug_log "H5_mesa_mix" "installWeston.sh:179" "No Mesa GL artifacts detected in rootfs" "rootfs=${BUILD_DIR}"
fi
# endregion

# ── Weston systemd service ────────────────────────────────────────────────────
echo "Installing weston systemd service..."
mkdir -p "$BUILD_DIR/etc/systemd/system"
cat > "$BUILD_DIR/etc/systemd/system/weston.service" <<'SERVICE'
[Unit]
Description=Weston Wayland Compositor
After=systemd-logind.service seatd.service
Wants=systemd-logind.service seatd.service

[Service]
Type=simple
User=rfnm
PAMName=login
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=wayland
Environment=LIBSEAT_BACKEND=seatd
Environment=SEATD_SOCK=/run/seatd.sock
ExecStartPre=+/bin/mkdir -p /run/user/1000
ExecStartPre=+/bin/chown rfnm:rfnm /run/user/1000
ExecStartPre=+/bin/chmod 700 /run/user/1000
ExecStart=/usr/bin/weston --backend=drm-backend.so --idle-time=0
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
SERVICE

chroot "$BUILD_DIR" systemctl enable weston

# region agent log H6
if [ -f "$BUILD_DIR/etc/systemd/system/weston.service" ]; then
    debug_log "H6_service_mode" "installWeston.sh:210" "weston systemd service installed" "service=weston.service;user=rfnm;backend=drm-backend.so"
fi
# endregion

echo "weston-imx ${WESTON_BRANCH} installed."
