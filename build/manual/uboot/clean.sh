#!/bin/sh

#---- Configurable Variables ----#
UBOOT_ROOT="../../../imx8mp-uboot"

#---- Clean ----#
rm -rf "./firmware"

cd "$UBOOT_ROOT"
git clean -fdx


