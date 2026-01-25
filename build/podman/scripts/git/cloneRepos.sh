#!/bin/sh

cd /work/build

# Clone repositories
git clone --recursive https://github.com/rfnm/imx8mp-kernel.git --depth 20 --shallow-submodules
git clone --recursive https://github.com/rfnm/imx8mp-uboot --depth 1 --shallow-submodules
git clone --recursive https://github.com/rfnm/la9310-driver.git --depth 1 --shallow-submodules
git clone --recursive https://github.com/rfnm/la9310-freertos.git --depth 1 --shallow-submodules
git clone --recursive https://github.com/nxp-imx/imx-atf.git --depth 1 --shallow-submodules
git clone --recursive https://github.com/rfnm/librfnm.git --depth 1 --shallow-submodules
