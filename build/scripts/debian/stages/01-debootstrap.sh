#!/bin/sh
# Stage 01 — debootstrap + configure
# Runs debootstrap first+second stage into $CHROOT_DIR, then configures
# packages, users, networking and Weston runtime dependencies — all within
# a single chroot mount session.
#
# Idempotent — skips already-completed steps on re-run.
set -e
. "$(dirname "$0")/common.sh"

BOOTSTRAPPED=0
[ -x "$CHROOT_DIR/bin/sh" ] && BOOTSTRAPPED=1
CONFIGURED=0
[ -f "$CHROOT_DIR/.stage-configure-done" ] && CONFIGURED=1

if [ "$BOOTSTRAPPED" -eq 1 ] && [ "$CONFIGURED" -eq 1 ]; then
    echo "[01-debootstrap] Already bootstrapped and configured, skipping."
    exit 0
fi

# ── Phase 1: debootstrap first stage (host-side, no chroot needed) ─────────────
if [ "$BOOTSTRAPPED" -eq 0 ]; then
    mkdir -p "$CHROOT_DIR"

    if [ ! -f "$CHROOT_DIR/debootstrap/debootstrap" ]; then
        echo "[01-debootstrap] Running debootstrap first stage..."
        debootstrap --arch=arm64 --foreign "$DEBIAN_RELEASE" "$CHROOT_DIR" "$MIRROR"
    fi

    echo "[01-debootstrap] Copying qemu-aarch64-static..."
    cp /usr/bin/qemu-aarch64-static "$CHROOT_DIR/usr/bin/"
fi

# ── Single chroot session for second stage + configure ─────────────────────────
mount_chroot
trap 'umount_chroot' EXIT

if [ "$BOOTSTRAPPED" -eq 0 ]; then
    echo "[01-debootstrap] Running debootstrap second stage inside chroot..."
    chroot "$CHROOT_DIR" /debootstrap/debootstrap --second-stage
fi

if [ "$CONFIGURED" -eq 0 ]; then
    echo "[01-debootstrap] Configuring users, packages and networking..."
    chroot "$CHROOT_DIR" /bin/bash <<EOF
set -e
export DEBIAN_FRONTEND=noninteractive

echo "root:${ROOT_PASSWORD}" | chpasswd

echo "rfnm" > /etc/hostname

useradd -m -s /bin/bash rfnm
echo "rfnm:rfnm" | chpasswd
usermod -aG sudo rfnm
groupadd -f seat
usermod -aG video,render,input,seat,tty rfnm

apt-get update

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
    gdb

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

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
    libgl1 \
    libegl-mesa0 

systemctl enable seatd

apt-get clean
EOF

    touch "$CHROOT_DIR/.stage-configure-done"
fi

umount_chroot
echo "[01-debootstrap] Done."
