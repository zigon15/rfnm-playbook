#!/bin/sh

#---- Build Kernel ----#
cd /work/build/imx8mp-kernel/

# Make config for i.MX8M
make imx8mp_rfnm_defconfig

# Disable proprietary GPU driver, enable open-source etnaviv
scripts/config --disable CONFIG_MXC_GPU_VIV
scripts/config --enable CONFIG_DRM_ETNAVIV
scripts/config --enable CONFIG_DRM_ETNAVIV_THERMAL

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