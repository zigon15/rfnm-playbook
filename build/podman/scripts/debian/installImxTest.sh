#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Target directory '$BUILD_DIR' does not exist!"
    echo "Did you run ./build.sh script first?"
    exit 1
fi

ABS_OUTPUT_DIR=$(realpath "$BUILD_DIR")

#---- Create Test Tools Directory ----#
TEST_DIR="$ABS_OUTPUT_DIR/usr/local/bin/"
mkdir -p "$TEST_DIR"

#---- Install IMX Test Tools ----#
echo "Installing IMX test tools to: $TEST_DIR"
cp -v /work/build/imx-test/test/memtool/memtool "$TEST_DIR/"

echo "Done! Test tools installed to: $TEST_DIR"