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

# Copy overlay if present
if [ -d "./rootfs-overlay" ]; then
    cp -r ./rootfs-overlay/* "$BUILD_DIR/"
fi

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
        build-essential

    # Enable networking
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
    systemctl enable systemd-timesyncd

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    # Graphics stack (etnaviv)
    apt-get install -y \
        mesa-utils \
        mesa-vulkan-drivers \
        libgl1-mesa-dri \
        libgbm1 \
        libdrm2 \
        xwayland \
        kwin-wayland

    # KDE Desktop
    apt-get install -y task-kde-desktop

    # GPU debug tools
    apt-get install -y vainfo

    # Mask services that fail on this hardware and cause boot delays
    systemctl mask plasma-powerdevil.service power-profiles-daemon.service

    apt-get clean

EOF

echo "Rootfs build complete."
