#!/bin/sh
set -e

# Desktop build using Mesa etnaviv (open-source Vivante GPU driver).
#
# Differences from buildDesktop_GalcoreGPU.sh:
#   - Does NOT install the proprietary Vivante EGL/OpenGL userspace.
#   - Mesa etnaviv provides OpenGL/EGL/GBM via the standard Debian packages.
#     This makes kwin_wayland, GLVND, and the standard GBM stack work correctly.
#   - Only Vivante's Vulkan ICD (libvulkan_VSI), OpenCL, and compute libs are
#     taken from the vivante overlay — they do not conflict with Mesa.
#
# Kernel requirement:
#   CONFIG_DRM_ETNAVIV=y (or =m) must be set in the kernel config.
#   The galcore module and etnaviv cannot run simultaneously.

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'
ROOT_PASSWORD="rfnm"
DEBIAN_RELEASE="trixie"
MIRROR="http://deb.debian.org/debian"

mkdir -p "$BUILD_DIR"

# Only run debootstrap if rootfs not already created
if [ ! -f "$BUILD_DIR/debootstrap/debootstrap" ]; then
    debootstrap --arch=arm64 --foreign "$DEBIAN_RELEASE" "$BUILD_DIR" "$MIRROR"
fi

# Ensure qemu is present inside rootfs
cp /usr/bin/qemu-aarch64-static "$BUILD_DIR/usr/bin/"

# Mount virtual filesystems needed by systemd inside chroot
mount -t proc proc "$BUILD_DIR/proc"
mount -t sysfs sysfs "$BUILD_DIR/sys"
mount --bind /dev "$BUILD_DIR/dev"

# Ensure cleanup on exit
cleanup() {
    umount "$BUILD_DIR/dev" "$BUILD_DIR/sys" "$BUILD_DIR/proc" 2>/dev/null || true
}
trap cleanup EXIT

# Run configuration inside chroot
chroot "$BUILD_DIR" /bin/bash <<EOF
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # Finish bootstrap
    /debootstrap/debootstrap --second-stage

    # Root password
    echo "root:$ROOT_PASSWORD" | chpasswd

    # Hostname
    echo "rfnm" > /etc/hostname

    # Desktop user
    useradd -m -s /bin/bash rfnm
    echo "rfnm:rfnm" | chpasswd
    usermod -aG sudo rfnm
    groupadd -f seat
    usermod -aG video,render,input,seat,tty rfnm

    apt-get update

    # Base utilities
    apt-get install -y \
        openssh-server \
        systemd-resolved \
        pciutils \
        systemd-timesyncd \
        htop \
        sudo \
        wget \
        u-boot-tools \
        build-essential \
        seatd \
        vulkan-tools \
        mesa-utils

    # Enable networking
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
    systemctl enable systemd-timesyncd

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    # Display stack — Mesa etnaviv provides EGL/OpenGL/GBM.
    # kwin-wayland links against Mesa's standard libEGL/libGBM/GLVND stack.
    apt-get install -y \
        libdrm2 \
        libpixman-1-0 \
        libxkbcommon0 \
        libwayland-server0 \
        libwayland-client0 \
        libpam0g \
        libinput10 \
        libseat1 \
        libva2 \
        libva-drm2 \
        xwayland \
        kwin-wayland

    # KDE Desktop
    apt-get install -y task-kde-desktop

    # Set SDDM as the display manager
    systemctl enable sddm

    # Enable seatd for non-root Wayland/GPU compositor access
    systemctl enable seatd

    # Update dynamic linker cache
    ldconfig

    # Mask services that fail on this hardware and cause boot delays
    systemctl mask plasma-powerdevil.service power-profiles-daemon.service

    apt-get clean

EOF

echo "Debian build complete."

# Apply base and desktop overlays.
# The vivante overlay is intentionally NOT applied here — Mesa etnaviv is used
# for OpenGL/EGL/GBM, and Vivante's proprietary libs would conflict with it.
for overlay in base desktop; do
    if [ -d "./rootfs-overlay/$overlay" ]; then
        echo "Installing $overlay overlay..."
        cp -rv "./rootfs-overlay/$overlay/"* "$BUILD_DIR/"
    fi
done

# Selectively install Vivante Vulkan ICD + compute libs.
# These use different subsystems and do NOT conflict with Mesa etnaviv:
#   - libvulkan_VSI.so  → Vivante Vulkan ICD (used by Vulkan apps directly)
#   - imx_icd.json      → Vulkan loader ICD manifest
#   - libgbm_viv.so     → Vivante's GBM backend plugin (Mesa GBM loads it, doesn't replace Mesa GBM)
#   - libOpenCL.so      → Vivante OpenCL implementation
#   - 10-imx.rules      → udev rule for /dev/galcore access
#   - opt/viv_samples   → GPU test binaries
if [ -d "./rootfs-overlay/vivante" ]; then
    echo "Installing Vivante Vulkan + compute components..."
    VDIR="./rootfs-overlay/vivante"
    LIBS="$BUILD_DIR/usr/lib/aarch64-linux-gnu"

    # Vulkan ICD
    mkdir -p "$BUILD_DIR/etc/vulkan/icd.d"
    cp -v "$VDIR/etc/vulkan/icd.d/imx_icd.json" "$BUILD_DIR/etc/vulkan/icd.d/"
    cp -av "$VDIR/usr/lib/aarch64-linux-gnu/libvulkan_VSI.so"* "$LIBS/"

    # Vivante GBM backend plugin (Mesa GBM loads this for hardware buffer allocation)
    cp -v "$VDIR/usr/lib/aarch64-linux-gnu/libgbm_viv.so" "$LIBS/"

    # OpenCL + compute
    cp -av "$VDIR/usr/lib/aarch64-linux-gnu/libOpenCL.so"* "$LIBS/" 2>/dev/null || true
    cp -v  "$VDIR/usr/lib/aarch64-linux-gnu/libCLC.so"        "$LIBS/" 2>/dev/null || true

    # udev rule for /dev/galcore
    mkdir -p "$BUILD_DIR/etc/udev/rules.d"
    cp -v "$VDIR/etc/udev/rules.d/10-imx.rules" "$BUILD_DIR/etc/udev/rules.d/"

    # Sample/test binaries
    if [ -d "$VDIR/opt" ]; then
        cp -rv "$VDIR/opt" "$BUILD_DIR/"
    fi
fi

# Update dynamic linker cache
chroot "$BUILD_DIR" ldconfig

echo "Overlay installation complete."
