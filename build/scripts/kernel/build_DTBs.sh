#!/bin/sh

#---- Build Device Trees only (fast, skips kernel Image + modules) ----#
cd /work/build/imx8mp-kernel/
make dtbs
