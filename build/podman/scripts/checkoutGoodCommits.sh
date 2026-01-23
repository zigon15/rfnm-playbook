#!/bin/sh

#-- Clean and checkout known good commits for all repositories
cd /work/build/imx8mp-kernel
git reset --hard HEAD
git clean -fdx
git checkout 0a92d165fba0e309a8a30601b12a2705b34a751e

cd /work/build/imx8mp-uboot
git reset --hard HEAD
git clean -fdx
git checkout b59a410ae137fd98ff97ac0165a83364ee4eebfa

cd /work/build/la9310-driver
git reset --hard HEAD
git clean -fdx
git checkout fbfeaced919d76eb02817a5ae683037f104f6bc9

cd /work/build/la9310-freertos
git reset --hard HEAD
git clean -fdx
git checkout 98253e7ebda79dcf420fb98bb60fd3b108cbc60e

cd /work/build/imx-atf
git reset --hard HEAD
git clean -fdx
git checkout a266ff458c2526a6474036a5c6648be6fdc54fe3

cd /work/build/librfnm
git reset --hard HEAD
git clean -fdx
git checkout df85a47569370a3de7987b7c36d77e843ec7a41f

#-- Apply required patches
cd /work/build/imx8mp-kernel
git apply /work/scripts/patches/imx8mp-kernel.patch

cd /work/build/imx8mp-uboot
git apply /work/scripts/patches/imx8mp-uboot.patch