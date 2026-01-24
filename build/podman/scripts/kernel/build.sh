#!/bin/sh

#---- Build Kernel ----#
cd /work/build/imx8mp-kernel/

# Make config for i.MX8M
make imx8mp_rfnm_defconfig

# Disable proprietary GPU driver, enable open-source etnaviv
scripts/config --disable CONFIG_MXC_GPU_VIV
scripts/config --enable CONFIG_DRM_ETNAVIV
scripts/config --enable CONFIG_DRM_ETNAVIV_THERMAL

# Enable required modules
# scripts/config --enable CONFIG_LEDS_RFNM_WSLED
# scripts/config --enable CONFIG_RFNM_SI5510
# scripts/config --enable CONFIG_RFNM_BOOTCONFIG

# Apply config changes
make olddefconfig

# Build the kernel Image and Device Trees
make -j$(nproc) Image dtbs

# Build the kernel modules
make -j$(nproc) modules
make modules_prepare