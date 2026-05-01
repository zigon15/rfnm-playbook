#!/bin/sh
set -e

#---- Build Kernel (Galcore / Vivante GPU) ----#
JOBS="${JOBS:-$(nproc)}"
BUILD_ERROR_LOG="/work/build/kernel-errors.log"

: > "$BUILD_ERROR_LOG"
echo "[build_GalcoreGPU] Writing errors to $BUILD_ERROR_LOG"
exec 2>> "$BUILD_ERROR_LOG"

cd /work/kernel/

# Make config for i.MX8M
make imx8mp_rfnm_defconfig

# Ensure proprietary Vivante GPU driver (galcore) is enabled, disable etnaviv to prevent conflicts

# Core DRM
scripts/config --enable CONFIG_MXC_GPU_VIV
scripts/config --disable CONFIG_DRM_ETNAVIV
scripts/config --disable CONFIG_DRM_ETNAVIV_THERMAL
scripts/config --enable CONFIG_DRM
scripts/config --enable CONFIG_DRM_KMS_HELPER
scripts/config --set-val CONFIG_DRM_FBDEV_OVERALLOC 100
scripts/config --enable CONFIG_DRM_PANEL
scripts/config --enable CONFIG_DRM_BRIDGE

# i.MX display (i.MX8MP uses LCDIFV3 + HDMI TX, not DCSS which is i.MX8MQ-only)
scripts/config --enable CONFIG_DRM_IMX
scripts/config --enable CONFIG_DRM_IMX_LCDIFV3
scripts/config --enable CONFIG_DRM_IMX_HDMI

# HDMI
scripts/config --module CONFIG_DRM_DW_HDMI
scripts/config --module CONFIG_DRM_DW_HDMI_CEC
scripts/config --enable CONFIG_DRM_CDNS_HDMI_CEC
scripts/config --enable CONFIG_PHY_FSL_SAMSUNG_HDMI_PHY

# Memory
scripts/config --enable CONFIG_CMA
scripts/config --enable CONFIG_DMA_CMA
scripts/config --set-val CONFIG_CMA_SIZE_MBYTES 256

# Sync
scripts/config --enable CONFIG_SYNC_FILE
scripts/config --enable CONFIG_DMA_SHARED_BUFFER

# Power / clocks / IOMMU
scripts/config --enable CONFIG_PM
scripts/config --enable CONFIG_PM_GENERIC_DOMAINS
scripts/config --enable CONFIG_COMMON_CLK
scripts/config --enable CONFIG_IOMMU_SUPPORT
scripts/config --enable CONFIG_ARM_SMMU

# Console
scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE
scripts/config --disable CONFIG_DRM_SIMPLEDRM


# User namespaces — required for systemd service sandboxing (upower, colord, etc.)
# Without this, sandboxed services fail with "Invalid argument" and cause ~5min login delay
scripts/config --enable CONFIG_NAMESPACES
scripts/config --enable CONFIG_USER_NS

# Disable automatic stack variable initialization for lower runtime overhead.
scripts/config --disable CONFIG_INIT_STACK_ALL_ZERO
scripts/config --disable CONFIG_INIT_STACK_ALL_PATTERN
scripts/config --enable CONFIG_INIT_STACK_NONE

# Root filesystem support. flashSD.sh formats partition 2 as ext4, so ext4 must
# be built into the kernel rather than left unset or modular.
scripts/config --enable CONFIG_EXT4_FS
scripts/config --enable CONFIG_EXT4_FS_POSIX_ACL

# Apply config changes
make olddefconfig

# Build the kernel Image and Device Trees
make -j"$JOBS" Image dtbs

if [ ! -f arch/arm64/boot/Image ]; then
	echo "Error: kernel Image was not produced." >&2
	exit 1
fi

if [ ! -f arch/arm64/boot/dts/freescale/imx8mp-rfnm.dtb ]; then
	echo "Error: RFNM device tree was not produced." >&2
	exit 1
fi

# Build the kernel modules
# modules_prepare must run before external modules can be compiled against this tree
make modules_prepare
make -j"$JOBS" modules
