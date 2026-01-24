#!/bin/sh

cd '/work/build/la9310-driver'

export KERNEL_DIR="/work/build/imx8mp-kernel"
export LA9310_COMMON_HEADERS="/work/build/la9310-freertos/common_headers"
export RFNM_BUILD_DIR="/work/build/"

make clean