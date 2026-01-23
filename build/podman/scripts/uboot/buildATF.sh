#!/bin/sh

cd /work/build/imx-atf
make PLAT=imx8mp bl31 CROSS_COMPILE=aarch64-linux-gnu-