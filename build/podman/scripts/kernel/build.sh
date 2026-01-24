#!/bin/sh

#---- Build Kernel ----#
cd /work/build/imx8mp-kernel/

# Make config for i.MX8M
make imx_v8_defconfig

# Build the kernel Image and Device Trees
make -j$(nproc) Image dtbs

# Build the kernel modules
make -j$(nproc) modules
make modules_prepare