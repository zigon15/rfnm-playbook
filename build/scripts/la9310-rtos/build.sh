#!/bin/sh

#---- Configurable Variables ----#
export ARMGCC_DIR=/usr

#---- Build ----#
cd '/work/build/la9310-freertos/Demo/CORTEX_M4_NXP_LA9310_GCC'
./build_release.sh -boot_mode=pci
