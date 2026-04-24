#!/bin/sh
# Stage 01 — debootstrap
# Runs debootstrap first+second stage into $CHROOT_DIR.
# Safe to re-run: skips everything if the rootfs already has a working shell.
set -e
. "$(dirname "$0")/common.sh"

if [ -x "$CHROOT_DIR/bin/sh" ]; then
    echo "[01-debootstrap] $CHROOT_DIR already bootstrapped, skipping."
    exit 0
fi

mkdir -p "$CHROOT_DIR"

if [ ! -f "$CHROOT_DIR/debootstrap/debootstrap" ]; then
    echo "[01-debootstrap] Running debootstrap first stage..."
    debootstrap --arch=arm64 --foreign "$DEBIAN_RELEASE" "$CHROOT_DIR" "$MIRROR"
fi

echo "[01-debootstrap] Copying qemu-aarch64-static..."
cp /usr/bin/qemu-aarch64-static "$CHROOT_DIR/usr/bin/"

mount_chroot
trap 'umount_chroot' EXIT

echo "[01-debootstrap] Running debootstrap second stage inside chroot..."
chroot "$CHROOT_DIR" /debootstrap/debootstrap --second-stage

echo "[01-debootstrap] Done."
