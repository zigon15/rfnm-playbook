#!/bin/sh
# Stage 05 — weston
# Builds weston-imx from source inside the arm64 chroot (QEMU emulation) and
# stages the installed artifacts to $WESTON_STAGE via meson DESTDIR.
#
# Requires 03-vivante.sh to have run first (Vivante headers + pkg-config must
# be present in $CHROOT_DIR/usr/).
#
# https://layers.openembedded.org/layerindex/recipe/402089/
set -e
. "$(dirname "$0")/common.sh"

if [ ! -x "$CHROOT_DIR/bin/sh" ]; then
    echo "Error: $CHROOT_DIR is not bootstrapped. Run stages 01–02 first."
    exit 1
fi

rm -rf \
    "$CHROOT_DIR/tmp/weston-imx-src" \
    "$CHROOT_DIR/tmp/wayland-protocols-imx-src" \
    "$CHROOT_DIR/tmp/wp-imx-build" \
    "$CHROOT_DIR/tmp/weston-imx-build" \
    "$CHROOT_DIR/tmp/weston-stage"

WESTON_REPO='https://github.com/nxp-imx/weston-imx.git'
WESTON_BRANCH='weston-imx-12.0.5'
WESTON_SRC='/work/build/weston-imx-src'

WP_IMX_REPO='https://github.com/nxp-imx/wayland-protocols-imx.git'
WP_IMX_TAG='lf-6.12.49-2.2.0'
WP_IMX_SRC='/work/build/wayland-protocols-imx-src'

# ── Clone on host (fast native git, cached) ───────────────────────────────────
if [ ! -d "$WESTON_SRC/.git" ]; then
    echo "[05-weston] Cloning weston-imx ${WESTON_BRANCH}..."
    git clone --branch "$WESTON_BRANCH" --depth 1 "$WESTON_REPO" "$WESTON_SRC"
else
    echo "[05-weston] Using cached weston-imx source at $WESTON_SRC"
fi

if [ ! -d "$WP_IMX_SRC/.git" ]; then
    echo "[05-weston] Cloning wayland-protocols-imx ${WP_IMX_TAG}..."
    git clone --branch "$WP_IMX_TAG" --depth 1 "$WP_IMX_REPO" "$WP_IMX_SRC"
else
    echo "[05-weston] Using cached wayland-protocols-imx source at $WP_IMX_SRC"
fi

# ── Stage sources inside chroot ───────────────────────────────────────────────
echo "[05-weston] Staging sources inside chroot..."
mkdir -p "$CHROOT_DIR/tmp"
rm -rf "$CHROOT_DIR/tmp/weston-imx-src"
cp -r "$WESTON_SRC" "$CHROOT_DIR/tmp/weston-imx-src"
rm -rf "$CHROOT_DIR/tmp/wayland-protocols-imx-src"
cp -r "$WP_IMX_SRC" "$CHROOT_DIR/tmp/wayland-protocols-imx-src"

# ── Mount chroot ──────────────────────────────────────────────────────────────
mount_chroot
trap 'umount_chroot' EXIT

# ── Install build dependencies inside arm64 chroot ───────────────────────────
echo "[05-weston] Installing build dependencies inside arm64 chroot (QEMU)..."
chroot "$CHROOT_DIR" /bin/sh <<'CHROOT_DEPS'
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
    echo "[05-weston] Patching chroot libdrm headers with NXP kernel version..."
    cp "$NXP_FOURCC" "$CHROOT_DIR/usr/include/libdrm/drm_fourcc.h"
else
    echo "[05-weston] Warning: NXP kernel not found at $NXP_FOURCC; build may fail with missing DRM modifier constants."
fi

# ── Build and install inside arm64 chroot (DESTDIR) ──────────────────────────
echo "[05-weston] Building weston-imx inside arm64 chroot (QEMU)..."
chroot "$CHROOT_DIR" /bin/sh <<'CHROOT'
set -e
export DEBIAN_FRONTEND=noninteractive

# Build and install wayland-protocols-imx (NXP fork) to provide the
# hdr10-metadata-unstable-v1.xml protocol required by weston-imx.
# Installed directly into the chroot (not DESTDIR'd) since it's a build dep.
meson setup /tmp/wp-imx-build /tmp/wayland-protocols-imx-src --prefix=/usr
ninja -C /tmp/wp-imx-build install
rm -rf /tmp/wayland-protocols-imx-src /tmp/wp-imx-build

# Configure weston-imx.
# Vivante EGL/GLES/GBM .pc files are in /usr/lib/aarch64-linux-gnu/pkgconfig
# (installed by 03-vivante.sh), so no PKG_CONFIG_PATH override is needed.
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

# Install to DESTDIR so artifacts can be extracted to the host staging dir.
DESTDIR=/tmp/weston-stage ninja -C /tmp/weston-imx-build install

rm -rf /tmp/weston-imx-src /tmp/weston-imx-build

# Restore the systemd resolv.conf symlink for the final system.
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
CHROOT

# ── Extract DESTDIR output to host staging dir ────────────────────────────────
echo "[05-weston] Extracting weston artifacts to $WESTON_STAGE..."
mkdir -p "$WESTON_STAGE"
cp -a "$CHROOT_DIR/tmp/weston-stage/." "$WESTON_STAGE/"
rm -rf "$CHROOT_DIR/tmp/weston-stage"

# ── Write weston systemd service to staging dir ───────────────────────────────
# systemctl enable runs in 06-merge.sh once weston.service is in the final rootfs.
echo "[05-weston] Writing weston.service to staging dir..."
mkdir -p "$WESTON_STAGE/etc/systemd/system"
cat > "$WESTON_STAGE/etc/systemd/system/weston.service" <<'SERVICE'
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
ExecStart=/usr/bin/weston --backend=drm-backend.so --idle-time=0 --log=/tmp/weston-service.log
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
SERVICE

echo "[05-weston] weston-imx ${WESTON_BRANCH} staged at ${WESTON_STAGE}."
