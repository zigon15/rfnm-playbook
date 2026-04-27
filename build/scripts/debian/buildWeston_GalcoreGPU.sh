#!/bin/sh
# Orchestrator: Weston + Vivante GL (download + compile)
#
# Stages:
#   1 — debootstrap+configure  (base Debian rootfs + packages, users, networking)
#   2 — vivante                (download Vivante GPU + Hantro VPU userspace → debian-stages/galcore/)
#   3 — weston                 (compile weston-imx   → debian-stages/weston/)
#   4 — optionals              (dispatch selected optional stages, e.g. gpu-sdk)
#   5 — merge+overlays         (apply overlays, wipe debian/, copy chroot + vivante + weston, ldconfig)
#   6 — kernel-modules         (install .ko files + NXP firmware into debian/)
#   7 — rfnm                   (LA9310 driver modules + FreeRTOS firmware into debian/)
#
# Optional stages (select via OPTIONAL_STAGES env var):
#   gpu-sdk  — compile gtec-demo-framework → debian-stages/gpu-sdk/opt/imx-gpu-sdk
#
# Run all stages (default):
#   ./buildWeston_GalcoreGPU.sh
#
# Run a specific subset of stages:
#   STAGES="2 5"   ./buildWeston_GalcoreGPU.sh   # vivante + merge
#   STAGES="6 7"   ./buildWeston_GalcoreGPU.sh   # re-install modules only
#   STAGES="5"     ./buildWeston_GalcoreGPU.sh   # just merge
#   OPTIONAL_STAGES="gpu-sdk" STAGES="1 2 3 4 5" ./buildWeston_GalcoreGPU.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/stages/common.sh"
STAGES="${STAGES:-1 2 3 4 5 6 7}"

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
run_stage 2 03-vivante.sh
run_stage 3 05-weston.sh

# ── Stage 4: run optional stages ───────────────────────────────────────────────
if should_run 4; then
    echo ""
    echo "════════════════════════════════════════"
    echo "  Stage 4 — optional stages"
    echo "════════════════════════════════════════"
fi
OPTIONAL_STAGES="${OPTIONAL_STAGES:-}"
for opt in $OPTIONAL_STAGES; do
    case "$opt" in
        gpu-sdk)
            "$SCRIPT_DIR/stages/optional/gpu-sdk.sh"
            ;;
        *)
            echo "[SKIP] Unknown optional stage: $opt"
            ;;
    esac
done

# ── Stage 5: merge + overlays ─────────────────────────────────────────────────
# Apply rootfs overlays, then assemble the final rootfs from staged directories,
# fix the libGLESv2 symlink, and run ldconfig.
if should_run 5; then
    echo ""
    echo "════════════════════════════════════════"
    echo "  Stage 5 — merge + overlays"
    echo "════════════════════════════════════════"

    if [ ! -d "$CHROOT_DIR" ]; then
        echo "Error: $CHROOT_DIR not found — run stage 1 first."
        exit 1
    fi

    # Apply rootfs overlays on top of the chroot.
    for overlay in base vivante; do
        overlay_dir="$SCRIPT_DIR/rootfs-overlay/$overlay"
        if [ -d "$overlay_dir" ]; then
            echo "Applying $overlay overlay..."
            cp -a "$overlay_dir/." "$CHROOT_DIR/"
        fi
    done
    if [ ! -d "$GALCORE_STAGE" ]; then
        echo "Error: $GALCORE_STAGE not found — run stage 2 (vivante) first."
        exit 1
    fi
    if [ ! -d "$WESTON_STAGE" ]; then
        echo "Error: $WESTON_STAGE not found — run stage 3 (weston) first."
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

    if [ -d "$GPU_SDK_STAGE" ]; then
        echo "Merging GPU SDK stage ($GPU_SDK_STAGE)..."
        cp -a "$GPU_SDK_STAGE/." "$BUILD_DIR/"
    else
        echo "[SKIP] $GPU_SDK_STAGE not found — skipping GPU SDK merge."
    fi

    ln -sf libGLESv2.so.2.0.0 \
        "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2"

    mount_chroot "$BUILD_DIR"
    trap 'umount_chroot "$BUILD_DIR"' EXIT
    chroot "$BUILD_DIR" ldconfig
    chroot "$BUILD_DIR" systemctl enable weston

    echo "Merge complete."
fi

run_stage 6 07-kernel-modules.sh
run_stage 7 08-rfnm.sh

echo ""
echo "✓  Weston rootfs build complete."
