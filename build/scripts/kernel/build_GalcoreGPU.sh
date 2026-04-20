#!/bin/sh

#---- Build Kernel (Galcore / Vivante GPU) ----#
cd /work/build/imx8mp-kernel/

# Make config for i.MX8M
make imx8mp_rfnm_defconfig

# Ensure proprietary Vivante GPU driver (galcore) is enabled, disable etnaviv to prevent conflicts
scripts/config --enable CONFIG_MXC_GPU_VIV
scripts/config --disable CONFIG_DRM_ETNAVIV
scripts/config --disable CONFIG_DRM_ETNAVIV_THERMAL

# Core DRM
scripts/config --enable CONFIG_DRM
scripts/config --enable CONFIG_DRM_KMS_HELPER
scripts/config --enable CONFIG_DRM_GEM_CMA_HELPER
scripts/config --enable CONFIG_DRM_KMS_CMA_HELPER
scripts/config --set-val CONFIG_DRM_FBDEV_OVERALLOC 100
scripts/config --enable CONFIG_DRM_PANEL
scripts/config --enable CONFIG_DRM_BRIDGE

# i.MX display
scripts/config --enable CONFIG_DRM_IMX
scripts/config --enable CONFIG_DRM_IMX_DCSS

# HDMI
scripts/config --enable CONFIG_DRM_IMX_HDMI
scripts/config --enable CONFIG_DRM_DW_HDMI
scripts/config --enable CONFIG_DRM_DW_HDMI_CEC

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
scripts/config --enable CONFIG_USER_NS

# Disable aggressive stack zeroing that causes USB buffer allocation failures
# Must disable ZERO and enable NONE to properly set choice block
scripts/config --disable CONFIG_INIT_STACK_ALL_ZERO
scripts/config --enable CONFIG_INIT_STACK_NONE

# Apply config changes
make olddefconfig

# Build the kernel Image and Device Trees
make -j$(nproc) Image dtbs

# Build the kernel modules
make -j$(nproc) modules
make modules_prepare
