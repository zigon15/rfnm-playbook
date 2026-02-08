#!/bin/sh

set -e

#-- Clean and checkout known good commits for all repositories
cd /work/build/imx8mp-kernel
git reset --hard d0d8e7db2919192bb3f8c84c0dd3a115f9e516e6
git clean -fdx

cd /work/build/imx8mp-uboot
git reset --hard b59a410ae137fd98ff97ac0165a83364ee4eebfa
git clean -fdx

cd /work/build/la9310-driver
git reset --hard fbfeaced919d76eb02817a5ae683037f104f6bc9
git clean -fdx

cd /work/build/la9310-freertos
git reset --hard 98253e7ebda79dcf420fb98bb60fd3b108cbc60e
git clean -fdx

cd /work/build/imx-atf
git reset --hard a266ff458c2526a6474036a5c6648be6fdc54fe3
git clean -fdx

cd /work/build/librfnm
git reset --hard df85a47569370a3de7987b7c36d77e843ec7a41f
git clean -fdx

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