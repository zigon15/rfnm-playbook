#!/bin/sh
# Orchestrator: Base rootfs + Vivante GL userspace
#
# Stages:
#   1 - debootstrap+configure  (base Debian rootfs + packages, users, networking)
#   2 - vivante                (download Vivante GPU + Hantro VPU userspace -> debian-stages/galcore/)
#   5 - merge+overlays         (apply overlays, wipe debian/, copy chroot + vivante, ldconfig)
#   6 - kernel-modules         (install .ko files + NXP firmware into debian/)
#   7 - rfnm                   (LA9310 driver modules + FreeRTOS firmware into debian/)
#
# Run all stages (default):
#   ./build_GalcoreGPU.sh
#
# Run a specific subset of stages:
#   STAGES="2 5" ./build_GalcoreGPU.sh   # vivante + merge
#   STAGES="5"   ./build_GalcoreGPU.sh   # just merge
#   STAGES="6 7" ./build_GalcoreGPU.sh   # re-install modules/RFNM only
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/stages/common.sh"
STAGES="${STAGES:-1 2 5 6 7}"

should_run() {
    num=$1
    for s in $STAGES; do
        [ "$s" = "$num" ] && return 0
    done
    return 1
}

run_stage() {
    num=$1 script=$2
    if ! should_run "$num"; then
        echo "[SKIP] Stage $num - $script"
        return 0
    fi
    echo ""
    echo "========================================"
    echo "  Stage $num - $script"
    echo "========================================"
    "$SCRIPT_DIR/stages/$script"
}

run_stage 1 01-debootstrap.sh
run_stage 2 03-vivante.sh

# Stage 5: merge + overlays.
if should_run 5; then
    echo ""
    echo "========================================"
    echo "  Stage 5 - merge + overlays"
    echo "========================================"

    if [ ! -d "$CHROOT_DIR" ]; then
        echo "Error: $CHROOT_DIR not found - run stage 1 first."
        exit 1
    fi
    if [ ! -d "$GALCORE_STAGE" ]; then
        echo "Error: $GALCORE_STAGE not found - run stage 2 (vivante) first."
        exit 1
    fi

    for overlay in base vivante; do
        overlay_dir="$SCRIPT_DIR/rootfs-overlay/$overlay"
        if [ -d "$overlay_dir" ]; then
            echo "Applying $overlay overlay..."
            cp -a "$overlay_dir/." "$CHROOT_DIR/"
        fi
    done

    echo "Wiping and recreating $BUILD_DIR..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    echo "Merging base chroot ($CHROOT_DIR)..."
    cp -a "$CHROOT_DIR/." "$BUILD_DIR/"

    echo "Merging Vivante driver stage ($GALCORE_STAGE)..."
    cp -a "$GALCORE_STAGE/." "$BUILD_DIR/"

    ln -sf libGLESv2.so.2.0.0 \
        "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2"

    mount_chroot "$BUILD_DIR"
    trap 'umount_chroot "$BUILD_DIR"' EXIT
    chroot "$BUILD_DIR" ldconfig
    umount_chroot "$BUILD_DIR"
    trap - EXIT

    echo "Merge complete."
fi

run_stage 6 07-kernel-modules.sh
run_stage 7 08-rfnm.sh

echo ""
echo "Base rootfs build complete."
