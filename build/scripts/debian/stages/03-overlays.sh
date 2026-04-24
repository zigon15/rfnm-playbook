#!/bin/sh
# Stage 03 — overlays
# Copies rootfs-overlay/base and rootfs-overlay/vivante into $CHROOT_DIR.
# Vivante driver runtime libraries and weston binaries are handled by later
# stages (04-galcore, 05-weston) or the merge script.
set -e
. "$(dirname "$0")/common.sh"

if [ ! -x "$CHROOT_DIR/bin/sh" ]; then
    echo "Error: $CHROOT_DIR is not bootstrapped. Run 01-debootstrap.sh first."
    exit 1
fi

for overlay in base vivante; do
    overlay_dir="$DEBIAN_DIR/rootfs-overlay/$overlay"
    if [ -d "$overlay_dir" ]; then
        echo "[03-overlays] Installing $overlay overlay..."
        cp -a "$overlay_dir/." "$CHROOT_DIR/"
    else
        echo "[03-overlays] $overlay overlay not found at $overlay_dir, skipping."
    fi
done

echo "[03-overlays] Done."
