#!/bin/sh
# Orchestrator: Weston + Vivante GL (download + compile)
#
# Stages:
#   1 — debootstrap      (base Debian rootfs in debian-build/)
#   2 — configure        (packages, users, networking)
#   3 — overlays         (rootfs-overlay/base + rootfs-overlay/vivante)
#   4 — vivante          (download Vivante GPU + Hantro VPU userspace → debian-stages/galcore/)
#   5 — weston           (compile weston-imx   → debian-stages/weston/)
#   6 — merge            (wipe debian/, copy chroot + vivante + weston, ldconfig)
#   7 — kernel-modules   (install .ko + NXP firmware, and optional RFNM artifacts)
#
# Run all stages (default):
#   ./buildWeston_GalcoreGPU.sh
#
# Run a specific subset of stages:
#   STAGES="4 6"   ./buildWeston_GalcoreGPU.sh   # vivante + merge
#   STAGES="7"     ./buildWeston_GalcoreGPU.sh   # re-install modules (+ optional RFNM)
#   STAGES="6"     ./buildWeston_GalcoreGPU.sh   # just merge
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/stages/common.sh"
STAGES="${STAGES:-1 2 3 4 5 6 7}"
RFNM_SUPPORT="${RFNM_SUPPORT:-1}"

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
        echo "[SKIP] Stage $num — $script"
        return 0
    fi
    echo ""
    echo "════════════════════════════════════════"
    echo "  Stage $num — $script"
    echo "════════════════════════════════════════"
    "$SCRIPT_DIR/stages/$script"
}

run_stage 1 01-debootstrap.sh
run_stage 2 02-configure.sh
run_stage 3 03-overlays.sh
run_stage 4 04-vivante.sh
run_stage 5 05-weston.sh

# ── Stage 6: merge ────────────────────────────────────────────────────────────
# Assemble the final rootfs from staged directories, fix the libGLESv2 symlink,
# and run ldconfig.
if should_run 6; then
    echo ""
    echo "════════════════════════════════════════"
    echo "  Stage 6 — merge"
    echo "════════════════════════════════════════"

    if [ ! -d "$CHROOT_DIR" ]; then
        echo "Error: $CHROOT_DIR not found — run stages 1-3 first."
        exit 1
    fi
    if [ ! -d "$GALCORE_STAGE" ]; then
        echo "Error: $GALCORE_STAGE not found — run stage 4 (vivante) first."
        exit 1
    fi
    if [ ! -d "$WESTON_STAGE" ]; then
        echo "Error: $WESTON_STAGE not found — run stage 5 (weston) first."
        exit 1
    fi

    echo "Wiping and recreating $BUILD_DIR..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    echo "Merging base chroot ($CHROOT_DIR)..."
    cp -a "$CHROOT_DIR/." "$BUILD_DIR/"

    echo "Merging Vivante driver stage ($GALCORE_STAGE)..."
    cp -a "$GALCORE_STAGE/." "$BUILD_DIR/"

    echo "Merging weston stage ($WESTON_STAGE)..."
    cp -a "$WESTON_STAGE/." "$BUILD_DIR/"

    ln -sf libGLESv2.so.2.0.0 \
        "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2"

    mount_chroot "$BUILD_DIR"
    trap 'umount_chroot "$BUILD_DIR"' EXIT
    chroot "$BUILD_DIR" ldconfig
    chroot "$BUILD_DIR" systemctl enable weston

    echo "Merge complete."
fi

run_stage 7 07-kernel-modules.sh

if [ "$RFNM_SUPPORT" = "1" ]; then
    echo ""
    echo "════════════════════════════════════════"
    echo "  RFNM install — sub/installRfnm.sh"
    echo "════════════════════════════════════════"
    "$SCRIPT_DIR/sub/installRfnm.sh"
else
    echo "[SKIP] RFNM install — RFNM_SUPPORT=0"
fi

echo ""
echo "✓  Weston rootfs build complete."
