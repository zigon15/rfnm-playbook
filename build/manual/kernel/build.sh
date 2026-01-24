#!/bin/sh

#---- Configurable Variables ----#
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

#---- Build Kernel ----#
cd ../../../../imx8mp-kernel/

# Make config for i.MX8M
make imx_v8_defconfig

# Disable proprietary GPU driver, enable open-source etnaviv
scripts/config --disable CONFIG_MXC_GPU_VIV

# Enable it as a module
scripts/config --enable CONFIG_LEDS_RFNM_WSLED
scripts/config --enable CONFIG_RFNM_SI5510

# Apply config changes
make olddefconfig

# Build the kernel Image and Device Trees
make -j$(nproc) Image dtbs

# Build the kernel modules
make -j$(nproc) modules
make modules_prepare