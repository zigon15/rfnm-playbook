#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='../../../build'
ROOT_PASSWORD="rfnm"

#---- Create Debian Root Filesystem ----#
OUTPUT_DIR="$BUILD_DIR/rfnm-debian-rootfs"
sudo rm -rf "$OUTPUT_DIR"
