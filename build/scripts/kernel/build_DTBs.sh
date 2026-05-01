#!/bin/sh

#---- Build Device Trees only (fast, skips kernel Image + modules) ----#
cd /work/kernel/

make dtbs
