#!/bin/sh
# Sourced by every stage script. Defines shared directory variables and
# chroot mount/unmount helpers. Do NOT execute directly.

# ── Output directories ────────────────────────────────────────────────────────
CHROOT_DIR="${CHROOT_DIR:-/work/build/debian-build}"      # live chroot workspace (stages 01-05)
GALCORE_STAGE="${GALCORE_STAGE:-/work/build/debian-stages/galcore}"  # Vivante runtime staging
WESTON_STAGE="${WESTON_STAGE:-/work/build/debian-stages/weston}"    # weston-imx DESTDIR staging
GPU_SDK_STAGE="${GPU_SDK_STAGE:-/work/build/debian-stages/gpu-sdk}"  # GPU SDK demo-framework staging
BUILD_DIR="${BUILD_DIR:-/work/build/debian}"             # final assembled rootfs (stage 06 only)

# ── Debian bootstrap config ───────────────────────────────────────────────────
ROOT_PASSWORD='rfnm'
DEBIAN_RELEASE='trixie'
MIRROR='http://deb.debian.org/debian'

# ── Derived paths ─────────────────────────────────────────────────────────────
# DEBIAN_DIR = the debian/ script directory (parent of stages/).
# $0 is the top-level script even when this file is sourced, so dirname($0)
# gives the stages/ dir and one level up gives debian/.
DEBIAN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEBUG_LOG_PATH="${DEBUG_LOG_PATH:-/work/.cursor/debug-cbba97.log}"
DEBUG_RUN_ID="${DEBUG_RUN_ID:-pre-fix}"

# ── Chroot mount helpers ──────────────────────────────────────────────────────
mount_chroot() {
    dir="${1:-$CHROOT_DIR}"
    mount -t proc  proc   "$dir/proc"
    mount -t sysfs sysfs  "$dir/sys"
    mount --bind   /dev   "$dir/dev"
}

umount_chroot() {
    dir="${1:-$CHROOT_DIR}"
    umount "$dir/dev"  2>/dev/null || true
    umount "$dir/sys"  2>/dev/null || true
    umount "$dir/proc" 2>/dev/null || true
}

debug_log() {
    hypothesis_id="$1"
    location="$2"
    message="$3"
    data="$4"
    mkdir -p "$(dirname "$DEBUG_LOG_PATH")"
    ts="$(date +%s%3N 2>/dev/null || echo 0)"
    printf '{"sessionId":"cbba97","runId":"%s","hypothesisId":"%s","location":"%s","message":"%s","data":{"details":"%s"},"timestamp":%s}\n' \
        "$DEBUG_RUN_ID" "$hypothesis_id" "$location" "$message" "$data" "$ts" >> "$DEBUG_LOG_PATH"
}
