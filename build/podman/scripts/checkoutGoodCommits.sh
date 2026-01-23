#!/bin/sh

cd /work/build/imx8mp-kernel
git checkout 0a92d165fba0e309a8a30601b12a2705b34a751e

cd /work/build/imx8mp-uboot
git checkout b59a410ae137fd98ff97ac0165a83364ee4eebfa

cd /work/build/la9310-driver
git checkout fbfeaced919d76eb02817a5ae683037f104f6bc9

cd /work/build/la9310-freertos
git checkout 98253e7ebda79dcf420fb98bb60fd3b108cbc60e

cd /work/build/imx-atf
git checkout a266ff458c2526a6474036a5c6648be6fdc54fe3

cd /work/build/librfnm
git checkout df85a47569370a3de7987b7c36d77e843ec7a41f