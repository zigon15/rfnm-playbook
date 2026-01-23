#!/bin/sh

DIR="./firmware/atf"

mkdir -p $DIR
ABS_DIR=$(realpath "$DIR")

cd "../../../imx-atf/"
make PLAT=imx8mp bl31 CROSS_COMPILE=aarch64-linux-gnu-

cp build/imx8mp/release/bl31.bin "$ABS_DIR/"