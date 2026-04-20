#!/bin/bash

#---- PATHS (Adjust these to match your actual build paths) ----#
UBOOT_ROOT="/work/build/imx8mp-uboot"

# Use FLASH_DEVICE env var if set, otherwise use $1
DEVICE="${FLASH_DEVICE:-$1}"

if [ -z "$DEVICE" ]; then
    echo "Usage: $0 <sd-device>"
    echo "Example: $0 /dev/sdb"
    echo "Alternatively, set the FLASH_DEVICE environment variable."
    exit 1
fi

#---- CHECKS ----#

# 0. Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# 1. Check if device exists and is a block device
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a block device or does not exist."
    exit 1
fi

# 2. Check existence of required files
UBOOT_IMAGE="${UBOOT_ROOT}/flash.bin"

if [ ! -f "$UBOOT_IMAGE" ]; then
    echo "Error: File not found -> $UBOOT_IMAGE"
    echo "Please fix the paths in the script variables."
    exit 1
fi

# 3. SAFETY CHECK: Is it a system drive?
if lsblk -no MOUNTPOINTS "$DEVICE" | grep -qE '^(/|/boot|/boot/efi)$'; then
    echo "ERROR: $DEVICE is a system drive (contains / or /boot mount points)!"
    exit 1
fi

echo "Target SD Card: $DEVICE"
echo "Unmounting..."
umount "$DEVICE"* 2>/dev/null

#---- STEP 1: PARTITIONING ----#
# Single FAT32 boot partition starting at 8MB offset.
# The 8MB offset is CRITICAL to leave space for flash.bin (sits at 32KB, ~1.5MB).
echo "Creating partition table..."
sfdisk --delete "$DEVICE" 2>/dev/null || true
sfdisk "$DEVICE" << EOF
start=16384, type=c
EOF
# start=16384 (8MB in 512-byte sectors), rest of card is the FAT32 boot partition

# Re-read partition table and wait for devices to be ready
partprobe "$DEVICE"
partx -u "$DEVICE" 2>/dev/null || true
sleep 3

# Wait for partition device to be created
for i in {1..10}; do
    if [ -b "${DEVICE}1" ]; then
        break
    fi
    sleep 0.5
done

#---- STEP 2: FLASH U-BOOT ----#
echo "Flashing U-Boot to raw offset..."
dd if="$UBOOT_IMAGE" of="$DEVICE" bs=1K seek=32 conv=fsync status=none

#---- STEP 3: FORMAT BOOT PARTITION & COPY BOOT FILES ----#
PART1="${DEVICE}1"

echo "Formatting BOOT ($PART1)..."
mkfs.vfat -n "BOOT" "$PART1" || { echo "Error: Failed to format FAT32 partition"; exit 1; }

# The SD card boot partition only holds boot.scr.
# Kernel, DTB, and rootfs all live on the USB drive.
echo "Generating boot.cmd (kernel and rootfs from USB)..."
MOUNT_POINT_BOOT=$(mktemp -d)
mount "$PART1" "$MOUNT_POINT_BOOT" || { echo "Error: Failed to mount BOOT partition"; exit 1; }

# USB partition layout: sda1=FAT32 (kernel/DTB), sda2=ext4 (rootfs)
# rootwait is essential as USB storage enumerates after kernel starts
cat << 'EOF' > "$MOUNT_POINT_BOOT/boot.cmd"
usb start
setenv bootargs console=tty0 console=ttymxc1,115200 earlycon root=/dev/sda2 rootwait rw
load usb 0:1 ${loadaddr} Image
load usb 0:1 ${fdt_addr} imx8mp-rfnm.dtb
booti ${loadaddr} - ${fdt_addr}
EOF

# Compile boot.scr if mkimage exists
if command -v mkimage &> /dev/null; then
    mkimage -C none -A arm -T script -d "$MOUNT_POINT_BOOT/boot.cmd" "$MOUNT_POINT_BOOT/boot.scr"
    echo "boot.scr generated!"
else
    echo "WARNING: mkimage not found. You will need to type boot commands manually."
fi

umount "$MOUNT_POINT_BOOT" || { echo "Error: Failed to unmount BOOT partition"; exit 1; }
rmdir "$MOUNT_POINT_BOOT" || { echo "Error: Failed to remove BOOT mount directory"; exit 1; }

echo "---------------------------------"
echo "SUCCESS! SD Card prepared for USB boot."
echo "U-Boot is on the SD card; kernel, DTB, and rootfs are expected on the USB drive."
echo "Use copyRootfsToUSB.sh to prepare the USB drive, then insert both into the board."
echo ""
echo "Manual boot commands if boot.scr is not found:"
echo "   usb start"
echo "   setenv bootargs console=ttymxc1,115200 earlycon root=/dev/sda2 rootwait rw"
echo "   load usb 0:1 \${loadaddr} Image"
echo "   load usb 0:1 \${fdt_addr} imx8mp-rfnm.dtb"
echo "   booti \${loadaddr} - \${fdt_addr}"
