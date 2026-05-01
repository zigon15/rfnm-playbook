#!/bin/bash

#---- PATHS (Adjust these to match your actual build paths) ----#
UBOOT_ROOT="/work/build/imx8mp-uboot"
KERNEL_ROOT="/work/kernel"
DEBIAN_ROOT_FS="/work/build/debian"

# Image configuration
OUTPUT_IMAGE="${1:-/work/build/rfnm-image.img}"
IMAGE_SIZE_GB="${2:-4}"

if [ -z "$OUTPUT_IMAGE" ]; then
  echo "Usage: $0 <output_image> [size_gb]"
  echo "Example: $0 /work/build/rfnm-image.img 4"
  echo "Default size: 4 GB"
  exit 1
fi

#---- CHECKS ----#
# 0. Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# 1. Check existence of single files
UBOOT_IMAGE="${UBOOT_ROOT}/flash.bin"
KERNEL_IMAGE="${KERNEL_ROOT}/arch/arm64/boot/Image"
DTB_FILE="${KERNEL_ROOT}/arch/arm64/boot/dts/freescale/imx8mp-rfnm.dtb"

for file in "$UBOOT_IMAGE" "$KERNEL_IMAGE" "$DTB_FILE"; do
  if [ ! -f "$file" ]; then
    echo "Error: File not found -> $file"
    echo "Build or rebuild the missing artifact before creating the image."
    exit 1
  fi
done

# 2. Check existence of RootFS Directory
if [ ! -d "$DEBIAN_ROOT_FS" ]; then
  echo "Error: RootFS directory not found -> $DEBIAN_ROOT_FS"
  exit 1
fi

# 3. Check if output image already exists
if [ -f "$OUTPUT_IMAGE" ]; then
  echo "Warning: Output image already exists: $OUTPUT_IMAGE"
  read -p "Overwrite? (yes/no): " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then exit 1; fi
  rm -f "$OUTPUT_IMAGE"
fi

echo "Creating image: $OUTPUT_IMAGE"
echo "Size: ${IMAGE_SIZE_GB} GB"

#---- STEP 1: CREATE IMAGE FILE ----#
echo "Creating sparse image file..."
IMAGE_SIZE_BYTES=$((IMAGE_SIZE_GB * 1024 * 1024 * 1024))
dd if=/dev/zero of="$OUTPUT_IMAGE" bs=1M count=0 seek=$((IMAGE_SIZE_GB * 1024)) status=none
echo "Image file created: $(ls -lh "$OUTPUT_IMAGE" | awk '{print $5}')"

#---- STEP 2: ATTACH LOOP DEVICE ----#
echo "Attaching loop device..."
LOOP_DEVICE=$(losetup -f)
losetup -P "$LOOP_DEVICE" "$OUTPUT_IMAGE"
echo "Using loop device: $LOOP_DEVICE"

# Trap to clean up on exit
cleanup() {
  echo "Cleaning up..."
  umount "${LOOP_DEVICE}p1" 2>/dev/null
  umount "${LOOP_DEVICE}p2" 2>/dev/null
  losetup -d "$LOOP_DEVICE" 2>/dev/null
}
trap cleanup EXIT

#---- STEP 3: PARTITIONING ----#
# We create a 100MB FAT32 partition starting at 8MB offset.
# The 8MB offset is CRITICAL to leave space for 'flash.bin' (which sits at 32KB and is ~1.5MB).
echo "Creating partition table..."
sfdisk --delete "$LOOP_DEVICE" 2>/dev/null || true
sfdisk "$LOOP_DEVICE" << EOF
start=16384, size=204800, type=c
start=221184, type=83
EOF
# Note: start=16384 (8MB), size=204800 (100MB) for FAT32 partition
# Second partition starts at sector 221184 (after partition 1) and uses remaining space
# Explicit sector-based partitioning ensures no overlap with U-Boot.

# Re-read partition table
sleep 1

#---- STEP 4: FLASH U-BOOT ----#
echo "Flashing U-Boot to raw offset..."
dd if="$UBOOT_IMAGE" of="$LOOP_DEVICE" bs=1K seek=32 conv=fsync status=none

#---- STEP 5: FORMAT & COPY BOOT FILES ----#
PART1="${LOOP_DEVICE}p1"
PART2="${LOOP_DEVICE}p2"

echo "Formatting BOOT ($PART1)..."
mkfs.vfat -n "BOOT" "$PART1"

echo "Formatting ROOTFS ($PART2)..."
mkfs.ext4 -F -L "rootfs" "$PART2"

# --- COPY BOOT FILES ---
echo "Mounting BOOT and copying kernel..."
MOUNT_POINT_BOOT=$(mktemp -d)
mount "$PART1" "$MOUNT_POINT_BOOT"

cp "$KERNEL_IMAGE" "$MOUNT_POINT_BOOT/"
cp "$DTB_FILE" "$MOUNT_POINT_BOOT/"

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

umount "$MOUNT_POINT_BOOT"
rmdir "$MOUNT_POINT_BOOT"

#---- STEP 6: COPY ROOT FILESYSTEM ----#
echo "Mounting ROOTFS and copying Debian files (This may take a while)..."
MOUNT_POINT_ROOT=$(mktemp -d)
mount "$PART2" "$MOUNT_POINT_ROOT"

# Use rsync to preserve all permissions, links, and ownership
# If you don't have rsync, use: cp -a "$DEBIAN_ROOT_FS/." "$MOUNT_POINT_ROOT/"
rsync -aAX --info=progress2 "$DEBIAN_ROOT_FS/" "$MOUNT_POINT_ROOT/" --exclude="sys" --exclude="proc" --exclude="dev" --exclude="tmp"

# Create mount point directories just in case they were excluded or missing
mkdir -p "$MOUNT_POINT_ROOT/sys" "$MOUNT_POINT_ROOT/proc" "$MOUNT_POINT_ROOT/dev" "$MOUNT_POINT_ROOT/tmp"

umount "$MOUNT_POINT_ROOT"
rmdir "$MOUNT_POINT_ROOT"

echo "---------------------------------"
echo "SUCCESS! Image created: $OUTPUT_IMAGE"
echo "Image size: $(ls -lh "$OUTPUT_IMAGE" | awk '{print $5}')"
echo ""
echo "To flash this image to an SD card:"
echo "  sudo dd if=$OUTPUT_IMAGE of=/dev/sdb bs=4M status=progress"
echo "  sudo sync"
echo ""
echo "To test in QEMU:"
echo "  qemu-system-aarch64 -M virt -m 2G -drive file=$OUTPUT_IMAGE,if=virtio,format=raw"
