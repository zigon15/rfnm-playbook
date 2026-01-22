#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='../../../build'
ROOT_PASSWORD="rfnm"

#---- Create Debian Root Filesystem ----#
OUTPUT_DIR="$BUILD_DIR/rfnm-debian-rootfs"
mkdir -p "$OUTPUT_DIR"

sudo debootstrap --arch=arm64 --foreign bookworm "$OUTPUT_DIR" http://deb.debian.org/debian
sudo cp /usr/bin/qemu-aarch64-static "$OUTPUT_DIR/usr/bin/"
sudo chroot "$OUTPUT_DIR" /bin/bash <<EOF
    # 1. Finish the bootstrap process
    /debootstrap/debootstrap --second-stage

    # 2. Set the root password non-interactively
    echo "root:$ROOT_PASSWORD" | chpasswd

    # 3. Set the hostname
    echo "rfnm" > /etc/hostname