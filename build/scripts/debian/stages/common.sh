#!/bin/sh
# Sourced by every stage script. Defines shared directory variables and
# chroot mount/unmount helpers. Do NOT execute directly.

# ── Output directories ────────────────────────────────────────────────────────
CHROOT_DIR='/work/build/debian-build'      # live chroot workspace (stages 01-05)
GALCORE_STAGE='/work/build/debian-stages/galcore'  # Vivante runtime staging
WESTON_STAGE='/work/build/debian-stages/weston'    # weston-imx DESTDIR staging
BUILD_DIR='/work/build/debian'             # final assembled rootfs (stage 06 only)

# ── Debian bootstrap config ───────────────────────────────────────────────────
ROOT_PASSWORD='rfnm'
DEBIAN_RELEASE='trixie'
MIRROR='http://deb.debian.org/debian'

# ── Derived paths ─────────────────────────────────────────────────────────────
# DEBIAN_DIR = the debian/ script directory (parent of stages/).
# $0 is the top-level script even when this file is sourced, so dirname($0)
# gives the stages/ dir and one level up gives debian/.
DEBIAN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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
