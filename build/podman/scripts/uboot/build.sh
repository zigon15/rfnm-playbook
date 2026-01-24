#!/bin/sh

#---- Configurable Variables ----#
export ATF_LOAD_ADDR=0x970000

UBOOT_ROOT="/work/build/imx8mp-uboot"

#---- Get Prerequisites ----#
#- DDR firmware
cp /work/build/firmware/firmware-imx-8.16/firmware/ddr/synopsys/lpddr4*.bin "$UBOOT_ROOT"

#- Arm Trusted Firmware
cp /work/build/imx-atf/build/imx8mp/release/bl31.bin "$UBOOT_ROOT"

#- RFNM shared header
cp /work/build/imx8mp-kernel/include/linux/rfnm-*.h "$UBOOT_ROOT/include/linux/"

#---- Build uBoot ----#
cd "$UBOOT_ROOT"
make mrproper
make imx8mp_rfnm_defconfig
make flash.bin \
    KCFLAGS="-Wno-int-conversion" \
    -j$(nproc)



