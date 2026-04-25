#!/bin/sh

set -e

# #-- Apply required patches
cd /work/build/imx8mp-kernel
git apply /work/scripts/patches/imx8mp-kernel.patch

cd /work/build/imx8mp-uboot
git apply /work/scripts/patches/imx8mp-uboot.patch

cd /work/build/imx-atf
git apply /work/scripts/patches/imx-atf.patch

cd /work/build/la9310-driver
git apply /work/scripts/patches/la9310-driver.patch

cd /work/build/la9310-driver/LimeSuiteNG
git apply /work/scripts/patches/LimeSuitNG.patch

cd /work/build/la9310-freertos
git apply /work/scripts/patches/la9310-freertos.patch