#!/bin/bash

# Flash a pre-built image file to an SD card device

# Use parameters: image file and target device
IMAGE_FILE="${1:-${"/work/build/rfnm-image.img":-}}"
DEVICE="${2:-${FLASH_DEVICE:-}}"

if [ -z "$IMAGE_FILE" ] || [ -z "$DEVICE" ]; then
    echo "Usage: $0 <image_file> <device>"
    echo "Example: $0 /work/build/rfnm-image.img /dev/sdb"
    echo ""
    echo "Alternatively, set environment variables:"
    echo "  export IMAGE_FILE=/path/to/image.img"
    echo "  export FLASH_DEVICE=/dev/sdb"
    echo "  $0"
    exit 1
fi

#---- CHECKS ----#

# 0. Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# 1. Check if image file exists and is readable
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file not found -> $IMAGE_FILE"
    exit 1
fi

if [ ! -r "$IMAGE_FILE" ]; then
    echo "Error: Image file is not readable -> $IMAGE_FILE"
    exit 1
fi

# 2. Check if device exists and is a block device
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a block device or does not exist."
    exit 1
fi

# 3. SAFETY CHECK: Is it a system drive?
# Check if the device or any of its partitions are mounted at / or /boot
if lsblk -no MOUNTPOINTS "$DEVICE" 2>/dev/null | grep -qE '^(/|/boot|/boot/efi)$'; then
    echo "ERROR: $DEVICE is a system drive (contains / or /boot mount points)!"
    exit 1
fi

# Display information
echo "Image file: $IMAGE_FILE"
IMAGE_SIZE=$(du -h "$IMAGE_FILE" | awk '{print $1}')
echo "Image size: $IMAGE_SIZE"
echo "Target device: $DEVICE"
echo ""

# Final confirmation
read -p "This will erase ALL data on $DEVICE. Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Unmount any mounted partitions on the device
echo "Unmounting partitions..."
umount "$DEVICE"* 2>/dev/null || { echo "Warning: Some partitions may still be mounted, attempting to proceed..."; }

# Wait for device to be ready
echo "Waiting for device to be ready..."
sleep 2
partprobe "$DEVICE" 2>/dev/null || true
partx -u "$DEVICE" 2>/dev/null || true
sleep 1

# Flash the image
echo "Flashing image to $DEVICE (this may take a while)..."
dd if="$IMAGE_FILE" of="$DEVICE" bs=4M status=progress conv=fsync || { echo "Error: Failed to flash image to $DEVICE"; exit 1; }

# Ensure all data is written
echo "Syncing..."
sync || { echo "Error: Failed to sync data"; exit 1; }

echo "---------------------------------"
echo "SUCCESS! Image flashed to $DEVICE"
echo ""
echo "Next steps:"
echo "1. Eject the SD card: sudo eject $DEVICE"
echo "2. Insert into board and power on"
echo "3. If boot.scr is present, it should boot automatically"
