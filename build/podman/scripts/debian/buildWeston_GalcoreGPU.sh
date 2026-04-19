#!/bin/sh
set -e

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
        vulkan-tools

    # Enable networking
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
    systemctl enable systemd-timesyncd

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    # Weston runtime dependencies (Weston binary comes from rootfs overlay, built against Vivante EGL)
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
        xwayland
        
    # Enable seatd for non-root user support
    systemctl enable seatd

    apt-get clean

EOF

echo "Weston build complete."

# Apply each overlay component in dependency order:
#   base    - core system config (networking, ssh, serial, rfnm scripts, gpio, firmware)
#   vivante - Vivante GPU support files (udev rule, libjpeg)
#   weston  - Weston compositor binaries, libs, service & assets (built against Vivante EGL)
#
# Vivante GPU driver is installed via installGalcoreDriver.sh (downloaded from NXP)
# and must run AFTER apt-get to overwrite any Mesa libs pulled in as dependencies.
for overlay in base vivante weston; do
    if [ -d "./rootfs-overlay/$overlay" ]; then
        echo "Installing $overlay overlay..."
        cp -rv "./rootfs-overlay/$overlay/"* "$BUILD_DIR/"
    fi
done

# Install Vivante GPU userspace driver
./installGalcoreDriver.sh

# Fix libGLESv2.so.2 symlink to point to Vivante real impl, not GLVND stub
ln -sf libGLESv2.so.2.0.0 "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2"

# Remove Debian GLVND shims that conflict with Vivante's direct libraries
rm -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2.1.0"
rm -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libEGL.so.1.1.0"

# Update dynamic linker cache to pick up overlay libraries
chroot "$BUILD_DIR" ldconfig

# Enable services from overlays
if [ -f "$BUILD_DIR/etc/systemd/system/weston.service" ]; then
    echo "Enabling Weston service..."
    chroot "$BUILD_DIR" systemctl enable weston
fi

echo "Overlay installation complete."
