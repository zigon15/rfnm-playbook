#!/bin/bash

#---- PATHS (Adjust these to match your actual build paths) ----#
KERNEL_ROOT="/work/build/imx8mp-kernel"
DEBIAN_ROOT_FS="/work/build/debian"

# Use USB_DEVICE env var if set, otherwise use $1
DEVICE="${USB_DEVICE:-$1}"

if [ -z "$DEVICE" ]; then
    echo "Usage: $0 <usb-device>"
    echo "Example: $0 /dev/sdc"
    echo "Alternatively, set the USB_DEVICE environment variable."
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
KERNEL_IMAGE="${KERNEL_ROOT}/arch/arm64/boot/Image"
DTB_FILE="${KERNEL_ROOT}/arch/arm64/boot/dts/freescale/imx8mp-rfnm.dtb"

for file in "$KERNEL_IMAGE" "$DTB_FILE"; do
    if [ ! -f "$file" ]; then
        echo "Error: File not found -> $file"
        echo "Build or rebuild the missing artifact before flashing."
        exit 1
    fi
done

# 3. Check existence of RootFS directory
if [ ! -d "$DEBIAN_ROOT_FS" ]; then
    echo "Error: RootFS directory not found -> $DEBIAN_ROOT_FS"
    exit 1
fi

# 4. SAFETY CHECK: Is it a system drive?
if lsblk -no MOUNTPOINTS "$DEVICE" | grep -qE '^(/|/boot|/boot/efi)$'; then
    echo "ERROR: $DEVICE is a system drive (contains / or /boot mount points)!"
    exit 1
fi


echo "Target USB Drive: $DEVICE"
echo "Unmounting..."
umount "$DEVICE"* 2>/dev/null

#---- STEP 1: PARTITION USB DRIVE ----#
# Partition 1: 100MB FAT32 for kernel and DTB
# Partition 2: remaining space ext4 for rootfs (/dev/sda2)
# Standard 1MB (2048 sector) alignment for USB drives.
echo "Creating partition table..."
sfdisk --delete "$DEVICE" 2>/dev/null || true
sfdisk "$DEVICE" << EOF
start=2048, size=204800, type=c
start=206848, type=83
EOF

# Re-read partition table and wait for devices to be ready
partprobe "$DEVICE"
partx -u "$DEVICE" 2>/dev/null || true
sleep 3

# Wait for both partition devices to be created
for i in {1..10}; do
    if [ -b "${DEVICE}1" ] && [ -b "${DEVICE}2" ]; then
        break
    fi
    sleep 0.5
done

#---- STEP 2: FORMAT PARTITIONS ----#
PART1="${DEVICE}1"
PART2="${DEVICE}2"

echo "Formatting BOOT ($PART1) as FAT32..."
mkfs.vfat -n "BOOT" "$PART1" || { echo "Error: Failed to format FAT32 partition"; exit 1; }

echo "Formatting ROOTFS ($PART2) as ext4..."
mkfs.ext4 -F -L "rootfs" "$PART2" || { echo "Error: Failed to format ext4 partition"; exit 1; }

#---- STEP 3: COPY KERNEL AND DTB ----#
echo "Mounting BOOT and copying kernel and DTB..."
MOUNT_POINT_BOOT=$(mktemp -d)
mount "$PART1" "$MOUNT_POINT_BOOT" || { echo "Error: Failed to mount BOOT partition"; exit 1; }

cp "$KERNEL_IMAGE" "$MOUNT_POINT_BOOT/" || { echo "Error: Failed to copy kernel image"; exit 1; }
cp "$DTB_FILE" "$MOUNT_POINT_BOOT/" || { echo "Error: Failed to copy device tree blob"; exit 1; }

umount "$MOUNT_POINT_BOOT" || { echo "Error: Failed to unmount BOOT partition"; exit 1; }
rmdir "$MOUNT_POINT_BOOT" || { echo "Error: Failed to remove BOOT mount directory"; exit 1; }

#---- STEP 4: COPY ROOT FILESYSTEM ----#
echo "Mounting USB rootfs and copying Debian files (This may take a while)..."
MOUNT_POINT=$(mktemp -d)
mount "$PART2" "$MOUNT_POINT" || { echo "Error: Failed to mount ROOTFS partition"; exit 1; }

# Use rsync to preserve all permissions, links, and ownership
rsync -aAX --info=progress2 "$DEBIAN_ROOT_FS/" "$MOUNT_POINT/" \
    --exclude="sys" --exclude="proc" --exclude="dev" --exclude="tmp" \
    || { echo "Error: Failed to copy root filesystem"; exit 1; }

# Create mount point directories in case they were excluded or missing
mkdir -p "$MOUNT_POINT/sys" "$MOUNT_POINT/proc" "$MOUNT_POINT/dev" "$MOUNT_POINT/tmp"

umount "$MOUNT_POINT" || { echo "Error: Failed to unmount USB partition"; exit 1; }
rmdir "$MOUNT_POINT" || { echo "Error: Failed to remove mount directory"; exit 1; }

echo "---------------------------------"
echo "SUCCESS! USB drive is ready."
echo "  Partition 1 (FAT32): kernel + DTB"
echo "  Partition 2 (ext4):  rootfs"
echo "Insert both the prepared SD card (U-Boot) and this USB drive into the RFNM board."
echo "U-Boot will load the kernel from USB partition 1 and mount rootfs from USB partition 2 (/dev/sda2)."
