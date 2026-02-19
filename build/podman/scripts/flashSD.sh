#!/bin/bash

#---- PATHS (Adjust these to match your actual build paths) ----#
UBOOT_ROOT="/work/build/imx8mp-uboot"
KERNEL_ROOT="/work/build/imx8mp-kernel"
DEBIAN_ROOT_FS="/work/build/debian" 

# Use FLASH_DEVICE env var if set, otherwise use $1
DEVICE="${FLASH_DEVICE:-$1}"

if [ -z "$DEVICE" ]; then
    echo "Usage: $0 <device>"
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

# 2. Check existence of single files
UBOOT_IMAGE="${UBOOT_ROOT}/flash.bin"
KERNEL_IMAGE="${KERNEL_ROOT}/arch/arm64/boot/Image"
DTB_FILE="${KERNEL_ROOT}/arch/arm64/boot/dts/freescale/imx8mp-rfnm.dtb"

for file in "$UBOOT_IMAGE" "$KERNEL_IMAGE" "$DTB_FILE"; do
    if [ ! -f "$file" ]; then
        echo "Error: File not found -> $file"
        echo "Please fix the paths in the script variables."
        exit 1
    fi
done

# 3. Check existence of RootFS Directory
if [ ! -d "$DEBIAN_ROOT_FS" ]; then
    echo "Error: RootFS directory not found -> $DEBIAN_ROOT_FS"
    exit 1
fi

# 4. SAFETY CHECK: Is it a system drive?
# Check if the device or any of its partitions are mounted at / or /boot
if lsblk -no MOUNTPOINTS "$DEVICE" | grep -qE '^(/|/boot|/boot/efi)$'; then
    echo "ERROR: $DEVICE is a system drive (contains / or /boot mount points)!"
    exit 1
fi

if [[ "$DEVICE" == *"/dev/sda"* ]] || [[ "$DEVICE" == *"/dev/nvme0n1"* ]]; then
    echo "WARNING: Target is $DEVICE. This might be a SYSTEM DRIVE."
    read -p "Are you ABSOLUTELY sure you want to wipe and flash $DEVICE? Type 'yes' to continue: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then exit 1; fi
fi

echo "Target: $DEVICE"
echo "Unmounting..."
umount "$DEVICE"* 2>/dev/null

#---- STEP 1: PARTITIONING ----#
# We create a 100MB FAT32 partition starting at 8MB offset.
# The 8MB offset is CRITICAL to leave space for 'flash.bin' (which sits at 32KB and is ~1.5MB).
echo "Creating partition table..."
sfdisk --delete "$DEVICE" 2>/dev/null || true
sfdisk "$DEVICE" << EOF
start=16384, size=204800, type=c
start=221184, type=83
EOF
# Note: start=16384 (8MB), size=204800 (100MB) for FAT32 partition
# Second partition starts at sector 221184 (after partition 1) and uses remaining space
# Explicit sector-based partitioning ensures no overlap with U-Boot.

# Re-read partition table and wait for devices to be ready
partprobe "$DEVICE"
partx -u "$DEVICE" 2>/dev/null || true
sleep 3

# Wait for partition devices to be created
for i in {1..10}; do
    if [ -b "${DEVICE}1" ] && [ -b "${DEVICE}2" ]; then
        break
    fi
    sleep 0.5
done

#---- STEP 2: FLASH U-BOOT ----#
echo "Flashing U-Boot to raw offset..."
dd if="$UBOOT_IMAGE" of="$DEVICE" bs=1K seek=32 conv=fsync status=none

#---- STEP 3: FORMAT & COPY BOOT FILES ----#
PART1="${DEVICE}1"
PART2="${DEVICE}2"

echo "Formatting BOOT ($PART1)..."
mkfs.vfat -n "BOOT" "$PART1" || { echo "Error: Failed to format FAT32 partition"; exit 1; }

echo "Formatting ROOTFS ($PART2)..."
mkfs.ext4 -F -L "rootfs" "$PART2" || { echo "Error: Failed to format ext4 partition"; exit 1; }

# --- COPY BOOT FILES ---
echo "Mounting BOOT and copying kernel..."
MOUNT_POINT_BOOT=$(mktemp -d)
mount "$PART1" "$MOUNT_POINT_BOOT" || { echo "Error: Failed to mount BOOT partition"; exit 1; }

cp "$KERNEL_IMAGE" "$MOUNT_POINT_BOOT/" || { echo "Error: Failed to copy kernel image"; exit 1; }
cp "$DTB_FILE" "$MOUNT_POINT_BOOT/" || { echo "Error: Failed to copy device tree blob"; exit 1; }

# Optional: Generate a boot.scr on the fly so you don't have to type commands manually
# This sets root=/dev/mmcblk1p2 (Partition 2)
echo "Generating boot.cmd..."
cat << 'EOF' > "$MOUNT_POINT_BOOT/boot.cmd"
setenv bootargs console=tty0 console=ttymxc1,115200 earlycon root=/dev/mmcblk1p2 rootwait rw
load mmc 1:1 ${loadaddr} Image
load mmc 1:1 ${fdt_addr} imx8mp-rfnm.dtb
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

#---- STEP 4: COPY ROOT FILESYSTEM ----#
echo "Mounting ROOTFS and copying Debian files (This may take a while)..."
MOUNT_POINT_ROOT=$(mktemp -d)
mount "$PART2" "$MOUNT_POINT_ROOT" || { echo "Error: Failed to mount ROOTFS partition"; exit 1; }

# Use rsync to preserve all permissions, links, and ownership
# If you don't have rsync, use: cp -a "$DEBIAN_ROOT_FS/." "$MOUNT_POINT_ROOT/"
rsync -aAX --info=progress2 "$DEBIAN_ROOT_FS/" "$MOUNT_POINT_ROOT/" --exclude="sys" --exclude="proc" --exclude="dev" --exclude="tmp" || { echo "Error: Failed to copy root filesystem"; exit 1; }

# Create mount point directories just in case they were excluded or missing
mkdir -p "$MOUNT_POINT_ROOT/sys" "$MOUNT_POINT_ROOT/proc" "$MOUNT_POINT_ROOT/dev" "$MOUNT_POINT_ROOT/tmp"

umount "$MOUNT_POINT_ROOT" || { echo "Error: Failed to unmount ROOTFS partition"; exit 1; }
rmdir "$MOUNT_POINT_ROOT" || { echo "Error: Failed to remove ROOTFS mount directory"; exit 1; }

echo "---------------------------------"
echo "SUCCESS! SD Card is ready."
echo "1. Insert into board."
echo "2. If 'boot.scr' was generated, it should boot automatically."
echo "3. If NOT, run:"
echo "   setenv bootargs console=\${console},115200 earlycon root=/dev/mmcblk1p2 rootwait rw"
echo "   fatload mmc 1:1 \$loadaddr Image"
echo "   fatload mmc 1:1 \$fdt_addr imx8mp-rfnm.dtb"
echo "   booti \$loadaddr - \$fdt_addr"