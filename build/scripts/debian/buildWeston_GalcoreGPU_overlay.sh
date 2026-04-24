#!/bin/sh
# Orchestrator: Weston + Vivante GL (prebuilt overlay)
#
# Uses prebuilt artifacts from rootfs-overlay/ — no download or compilation.
#
# Stages:
#   1 — debootstrap      (base Debian rootfs in debian-build/)
#   2 — configure        (packages, users, networking)
#   3 — overlays         (rootfs-overlay/base + rootfs-overlay/vivante)
#   4 — merge-overlay    (wipe debian/, copy chroot + vivanteDrivers + weston, ldconfig)
#   5 — kernel-modules   (install .ko files + NXP firmware into debian/)
#   6 — rfnm             (LA9310 driver modules + FreeRTOS firmware into debian/)
#
# Run all stages (default):
#   ./buildWeston_GalcoreGPU_overlay.sh
#
# Run a specific subset of stages (merge always added automatically via build.py):
#   STAGES="5 6"   ./buildWeston_GalcoreGPU_overlay.sh   # re-install modules only
#   STAGES="4"     ./buildWeston_GalcoreGPU_overlay.sh   # just merge
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/stages/common.sh"
STAGES="${STAGES:-1 2 3 4 5 6}"

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

# ── Stage 4: merge-overlay ────────────────────────────────────────────────────
# Copy prebuilt vivanteDrivers and weston overlays directly into the final
# rootfs alongside the base chroot.
if should_run 4; then
    echo ""
    echo "════════════════════════════════════════"
    echo "  Stage 4 — merge-overlay"
    echo "════════════════════════════════════════"

    VIV_OVERLAY="$SCRIPT_DIR/rootfs-overlay/vivanteDrivers"
    WESTON_OVERLAY="$SCRIPT_DIR/rootfs-overlay/weston"

    if [ ! -d "$CHROOT_DIR" ]; then
        echo "Error: $CHROOT_DIR not found — run stages 1-3 first."
        exit 1
    fi
    if [ ! -d "$VIV_OVERLAY" ]; then
        echo "Error: $VIV_OVERLAY not found — is the repo fully cloned?"
        exit 1
    fi
    if [ ! -d "$WESTON_OVERLAY" ]; then
        echo "Error: $WESTON_OVERLAY not found — is the repo fully cloned?"
        exit 1
    fi

    echo "Wiping and recreating $BUILD_DIR..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    echo "Merging base chroot ($CHROOT_DIR)..."
    cp -a "$CHROOT_DIR/." "$BUILD_DIR/"

    echo "Merging vivanteDrivers overlay..."
    cp -a "$VIV_OVERLAY/." "$BUILD_DIR/"

    echo "Merging weston overlay..."
    cp -a "$WESTON_OVERLAY/." "$BUILD_DIR/"

    ln -sf libGLESv2.so.2.0.0 \
        "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2"

    mount_chroot "$BUILD_DIR"
    trap 'umount_chroot "$BUILD_DIR"' EXIT
    chroot "$BUILD_DIR" ldconfig
    chroot "$BUILD_DIR" systemctl enable weston

    echo "Overlay merge complete."
fi

run_stage 5 07-kernel-modules.sh
run_stage 6 08-rfnm.sh

echo ""
echo "✓  Weston overlay rootfs build complete."
