#!/bin/sh

mkdir -p /work/build/firmware
cd /work/build/firmware

wget -O firmware-imx-8.16.bin https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.16.bin
chmod +x firmware-imx-8.16.bin 
./firmware-imx-8.16.bin --auto-accept