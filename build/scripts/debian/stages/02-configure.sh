#!/bin/sh
# Stage 02 — configure
# Installs base packages, users, networking and Weston runtime deps inside
# the chroot at $CHROOT_DIR.
set -e
. "$(dirname "$0")/common.sh"

if [ ! -x "$CHROOT_DIR/bin/sh" ]; then
    echo "Error: $CHROOT_DIR is not bootstrapped. Run 01-debootstrap.sh first."
    exit 1
fi

mount_chroot
trap 'umount_chroot' EXIT

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
    vulkan-tools

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
    xwayland

systemctl enable seatd

apt-get clean
EOF

echo "[02-configure] Done."
