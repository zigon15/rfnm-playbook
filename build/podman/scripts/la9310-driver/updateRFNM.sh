#!/bin/sh

RFNM_IP="192.168.20.190"

#---- Get Kernel Version ----#
KERNEL_VERSION=$(ssh root@$RFNM_IP uname -r)
echo "Kernel version: $KERNEL_VERSION"

#---- Create Module Directory ----#
MODULE_DIR="/lib/modules/$KERNEL_VERSION/extra"

scp ../../build/la9310-driver/kernel_driver/la9310rfnm/*.ko root@$RFNM_IP:$MODULE_DIR/
scp ../../build/la9310-driver/kernel_driver/la9310shiva/*.ko root@$RFNM_IP:$MODULE_DIR/
