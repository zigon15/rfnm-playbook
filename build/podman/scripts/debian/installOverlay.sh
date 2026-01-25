#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'
ROOT_PASSWORD="rfnm"

#---- Create Debian Root Filesystem ----#
mkdir -p $BUILD_DIR

# Copy configuration overlay
if [ -d "./rootfs-overlay" ]; then
    cp -rv "./rootfs-overlay/"* "$BUILD_DIR/"
fi