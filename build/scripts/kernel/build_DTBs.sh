#!/bin/sh

#---- Build Device Trees only (fast, skips kernel Image + modules) ----#
cd /work/build/imx8mp-kernel/

/work/scripts/kernel/apply-rfnm-overlay.sh

make dtbs
