#!/bin/sh

DIR="./firmware/ddr"

mkdir -p $DIR
cd $DIR
wget -O firmware-imx-8.16.bin https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.16.bin
sudo chmod +x firmware-imx-8.16.bin
./firmware-imx-8.16.bin

