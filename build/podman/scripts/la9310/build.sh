#!/bin/sh

#---- Configurable Variables ----#
export KERNEL_DIR="/work/build/imx8mp-kernel/"
export LA9310_COMMON_HEADERS="/work/build/la9310-freertos/common_headers/"
export RFNM_BUILD_DIR="/work/build/"

#---- Build ----#
cd '/work/build/la9310-driver'
make KCFLAGS="-Wno-int-conversion -w" -j$(nproc)
# export CROSS_COMPILE_PATH = [path to cross compiler]
# export PATH=$CROSS_COMPILE_PATH:$PATH  