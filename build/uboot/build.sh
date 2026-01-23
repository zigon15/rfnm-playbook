#!/bin/sh

#---- Configurable Variables ----#
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export ATF_LOAD_ADDR=0x970000

UBOOT_ROOT="../../../imx8mp-uboot"

#---- Get Prerequisites ----#
#- DDR firmware
cp firmware/nxp/firmware-imx-8.16/firmware/ddr/synopsys/lpddr4*.bin "$UBOOT_ROOT"

#- Arm Trusted Firmware
cp firmware/atf/bl31.bin "$UBOOT_ROOT"

#- RFNM shared header
cp ../../../imx8mp-kernel/include/linux/rfnm-*.h "$UBOOT_ROOT/include/linux/"

#---- Build uBoot ----#
cd "$UBOOT_ROOT"
make mrproper
make imx8mp_rfnm_defconfig
# make KCFLAGS="-Wno-int-conversion" -j$(nproc) 
make flash.bin \
    KCFLAGS="-Wno-int-conversion" \
    -j$(nproc)

#---- Copy uBoot ----#



