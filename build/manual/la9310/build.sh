#!/bin/sh

#---- Configurable Variables ----#
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

ABS_OUTPUT_DIR=$(realpath "../../../../imx8mp-kernel")

export KERNEL_DIR=$(realpath "../../../../imx8mp-kernel")
export LA9310_COMMON_HEADERS=$(realpath "../../../../la9310-freertos/common_headers")
export RFNM_BUILD_DIR=$(realpath "../../../../")

#---- Build ----#
cd '../../../../la9310-driver'
make KCFLAGS="-Wno-int-conversion" -j$(nproc)
