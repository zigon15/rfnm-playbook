#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'
ROOT_PASSWORD="rfnm"

#---- Create Debian Root Filesystem ----#
mkdir -p $BUILD_DIR

debootstrap --arch=arm64 --foreign trixie "$BUILD_DIR" http://deb.debian.org/debian
cp /usr/bin/qemu-aarch64-static "$BUILD_DIR/usr/bin/"
chroot "$BUILD_DIR" /bin/bash <<EOF
    # 1. Finish the bootstrap process
    /debootstrap/debootstrap --second-stage

    # 2. Set the root password non-interactively
    echo "root:$ROOT_PASSWORD" | chpasswd

    # 3. Set the hostname
    echo "rfnm" > /etc/hostname