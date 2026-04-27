#!/bin/sh
# Stage 04 — GPU SDK (gtec-demo-framework)
# Builds the NXP GPU SDK demo framework inside the arm64 chroot.
#
# Requires stage 03 (vivante) to have run first — Vivante headers, libs,
# and pkg-config must be present in $CHROOT_DIR.
set -e
. "$(dirname "$0")/../common.sh"

rm -rf \
    "$CHROOT_DIR/tmp/gtec-demo-framework" \
    "$CHROOT_DIR/tmp/gpu-sdk-stage"

GPU_SDK_VERSION="6.1.1"
GPU_SDK_COMMIT="35bbd45ed6eac169a778bd154283771b9bf39be7"
GPU_SDK_CACHE="/work/build/gpu-sdk/gtec-demo-framework"

# ── Clone / update GPU SDK repo ──────────────────────────────────────────────
if [ ! -d "$GPU_SDK_CACHE/.git" ]; then
    echo "[04-gpu-sdk] Cloning gtec-demo-framework ${GPU_SDK_VERSION}..."
    mkdir -p /work/build/gpu-sdk
    git clone --branch master --depth 1 \
        https://github.com/nxp-imx/gtec-demo-framework.git \
        "$GPU_SDK_CACHE"
fi

cd "$GPU_SDK_CACHE"
CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")
if [ "$CURRENT_COMMIT" != "$GPU_SDK_COMMIT" ]; then
    echo "[04-gpu-sdk] Fetching gtec-demo-framework commit ${GPU_SDK_COMMIT}..."
    git fetch --depth 1 origin "$GPU_SDK_COMMIT" || {
        echo "Error: failed to fetch commit $GPU_SDK_COMMIT"
        exit 1
    }
    git checkout "$GPU_SDK_COMMIT" || {
        echo "Error: failed to checkout commit $GPU_SDK_COMMIT"
        exit 1
    }
else
    echo "[04-gpu-sdk] gtec-demo-framework already at correct commit, skipping fetch."
fi

# ── Build GPU SDK inside arm64 chroot ────────────────────────────────────────
mount_chroot
trap 'umount_chroot' EXIT

echo "[04-gpu-sdk] Installing GPU SDK build dependencies..."
chroot "$CHROOT_DIR" /bin/sh <<'SDK_DEPS'
set -e
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 8.8.8.8" > /etc/resolv.conf
apt-get update
apt-get install -y cmake ninja-build python3 libxrandr-dev libdevil-dev git libwayland-dev wayland-protocols libxkbcommon-dev
SDK_DEPS

echo "[04-gpu-sdk] Staging gtec-demo-framework source into chroot..."
rm -rf "$CHROOT_DIR/tmp/gtec-demo-framework"
cp -r "$GPU_SDK_CACHE" "$CHROOT_DIR/tmp/gtec-demo-framework"

# Some recipe URLs in older gtec-demo-framework commits point to paths
# that no longer exist (e.g. zlib.net drops old versions from the main
# page).  Pre-populate the download cache with known-good sources.
# Nuke any stale .Thirdparty from a previous failed build first so the
# --ForceClaimInstallArea below sees a fresh directory.
echo "[04-gpu-sdk] Pre-populating third-party download cache..."
rm -rf "$CHROOT_DIR/tmp/gtec-demo-framework/.Thirdparty"
SDK_DLCACHE="$CHROOT_DIR/tmp/gtec-demo-framework/.Thirdparty/.DownloadCache"
mkdir -p "$SDK_DLCACHE" /work/build/gpu-sdk/thirdparty

# zlib 1.2.13 — recipe points to /zlib-1.2.13.tar.gz which 404s;
# fossils/ keeps every released version.
ZLIBCACHE="/work/build/gpu-sdk/thirdparty/zlib-1.2.13.tar.gz"
if [ ! -f "$ZLIBCACHE" ]; then
    wget -O "$ZLIBCACHE" "https://zlib.net/fossils/zlib-1.2.13.tar.gz"
fi
cp "$ZLIBCACHE" "$SDK_DLCACHE/zlib-1.2.13.tar.gz"

echo "[04-gpu-sdk] Building GPU SDK inside arm64 chroot (QEMU)..."
chroot "$CHROOT_DIR" /bin/sh <<'SDK_BUILD'
set -e
cd /tmp/gtec-demo-framework
. ./prepare.sh

# GCC 14 (Debian Trixie) flags false positives in older third-party
# code the framework builds (assimp 5.2.5, etc.).  Downgrade those
# diagnostics from errors to warnings.
export CFLAGS="${CFLAGS} -Wno-error=free-nonheap-object -Wno-error=array-bounds -Wno-error=dangling-reference"
export CXXFLAGS="${CXXFLAGS} -Wno-error=free-nonheap-object -Wno-error=array-bounds -Wno-error=dangling-reference"

FslBuild.py -t sdk \
    --UseFeatures [ConsoleHost,WindowHost,EGL,OpenGLES2,OpenGLES3,OpenVG,G2D] \
    --Variants [WindowSystem=X11] \
    --BuildThreads $(nproc) \
    -c build \
    --ForceClaimInstallArea

# The aggregate "sdk" target does not expose a top-level install target
# under Ninja on this platform. Stage from deterministic build output dirs.
SDK_INSTALL_ROOT=/tmp/gpu-sdk-stage/opt/imx-gpu-sdk
rm -rf "$SDK_INSTALL_ROOT"
mkdir -p "$SDK_INSTALL_ROOT"

STAGED_ANY=0
if [ -d /tmp/gtec-demo-framework/bin ]; then
    mkdir -p "$SDK_INSTALL_ROOT/bin"
    cp -a /tmp/gtec-demo-framework/bin/. "$SDK_INSTALL_ROOT/bin/"
    STAGED_ANY=1
fi
if [ -d /tmp/gtec-demo-framework/build/Ubuntu/Ninja/release ]; then
    mkdir -p "$SDK_INSTALL_ROOT/build/Ubuntu/Ninja/release"
    cp -a /tmp/gtec-demo-framework/build/Ubuntu/Ninja/release/. \
        "$SDK_INSTALL_ROOT/build/Ubuntu/Ninja/release/"
    STAGED_ANY=1
fi
if [ "$STAGED_ANY" -ne 1 ]; then
    echo "[04-gpu-sdk] Error: no SDK artifacts found in expected build output paths."
    exit 1
fi

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
SDK_BUILD

# ── Extract DESTDIR output to host staging ──────────────────────────────────
echo "[04-gpu-sdk] Extracting GPU SDK artifacts to staging..."
rm -rf "$GPU_SDK_STAGE"
mkdir -p "$GPU_SDK_STAGE"
cp -a "$CHROOT_DIR/tmp/gpu-sdk-stage/." "$GPU_SDK_STAGE/"
rm -rf "$CHROOT_DIR/tmp/gpu-sdk-stage" "$CHROOT_DIR/tmp/gtec-demo-framework"

echo "[04-gpu-sdk] GPU SDK ${GPU_SDK_VERSION} staged → $GPU_SDK_STAGE"
