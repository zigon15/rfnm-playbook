#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'
ROOT_PASSWORD="rfnm"

#---- Create Debian Root Filesystem ----#
mkdir -p $BUILD_DIR

debootstrap --arch=arm64 --foreign trixie "$BUILD_DIR" http://deb.debian.org/debian
cp /usr/bin/qemu-aarch64-static "$BUILD_DIR/usr/bin/"

chroot "$BUILD_DIR" /bin/bash <<EOF
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # Finish the bootstrap process
    /debootstrap/debootstrap --second-stage

    # Set the root password non-interactively
    echo "root:$ROOT_PASSWORD" | chpasswd

    # Set the hostname
    echo "rfnm" > /etc/hostname

    # Non-root user
    useradd -m -s /bin/bash rfnm
    echo "rfnm:rfnm" | chpasswd
    usermod -aG sudo rfnm
    usermod -aG input,tty rfnm

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
        vulkan-tools

    # Enable networking
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
    systemctl enable systemd-timesyncd

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    apt-get clean
EOF


# Apply each overlay component in dependency order:
#   base     - core system config (networking, ssh, serial, rfnm scripts, gpio, firmware)
#   vivante  - Vivante GPU userspace libs + udev rules + gputop + viv_samples
#
# Vivante must be applied AFTER apt-get runs to overwrite any
# Mesa libs pulled in as dependencies.
for overlay in base vivante; do
    if [ -d "./rootfs-overlay/$overlay" ]; then
        echo "Installing $overlay overlay..."
        cp -rv "./rootfs-overlay/$overlay/"* "$BUILD_DIR/"
    fi
done

# Remove GLVND dispatcher shims that conflict with Vivante's direct libraries.
# ldconfig picks the highest version number, so these shims (which lack actual
# GL implementation) would override the real Vivante drivers without removal.
if [ -d "./rootfs-overlay/vivante" ]; then
    echo "Removing GLVND shims that conflict with Vivante..."
    rm -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2.1.0"
    rm -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libEGL.so.1.1.0"
fi

# Update dynamic linker cache to pick up overlay libraries
chroot "$BUILD_DIR" ldconfig

echo "Overlay installation complete."