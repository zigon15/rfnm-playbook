#!/bin/sh

set -e

#---- Configurable Variables ----#                                                                                            
CROSS_COMPILE=aarch64-linux-gnu-                                                                                              
KERNEL_SRC=/work/build/imx8mp-kernel                                                                                                
                                                                                                                            
#---- Install kernel headers ----#                                                                                            
cd "${KERNEL_SRC}"                                                                                                            
make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} headers_install INSTALL_HDR_PATH=/usr/aarch64-linux-gnu 

#---- Build ----#                                                                                                             
cd '/work/build/imx-test'                                                                                                     
make all \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC=${CROSS_COMPILE}gcc \
    LD=${CROSS_COMPILE}ld \
    STRIP=${CROSS_COMPILE}strip \
    CFLAGS="-std=gnu11"
    