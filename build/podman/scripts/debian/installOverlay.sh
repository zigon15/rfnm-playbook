#!/bin/sh

#---- Configurable Variables ----#
BUILD_DIR='/work/build/debian'

#---- Install Overlays to Debian Root Filesystem ----#

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Target directory '$BUILD_DIR' does not exist!"
    echo "Did you run the build script first?"
    exit 1
fi

# Apply each overlay component in dependency order:
#   base     - core system config (networking, ssh, serial, rfnm scripts, gpio, firmware)
#   vivante  - Vivante GPU userspace libs + udev rules + gputop + viv_samples
#   weston   - Weston compositor binaries, libs, service & assets (built against Vivante EGL)
#   desktop  - KDE/SDDM desktop environment config
#
# Vivante & weston must be applied AFTER apt-get runs to overwrite any
# Mesa libs pulled in as dependencies.
for overlay in base vivante weston desktop; do
    if [ -d "./rootfs-overlay/$overlay" ]; then
        echo "Installing $overlay overlay..."
        cp -rv "./rootfs-overlay/$overlay/"* "$BUILD_DIR/"
    fi
done

# Remove GLVND dispatcher shims that conflict with Vivante's direct libraries.
# ldconfig picks the highest version number, so these shims (which lack actual
# GL implementation) would override the real Vivante drivers without removal.
if [ -d "./rootfs-overlay/vivante" ]; then
    echo "Removing GLVND shims that conflict with Vivante..."
    rm -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libGLESv2.so.2.1.0"
    rm -f "$BUILD_DIR/usr/lib/aarch64-linux-gnu/libEGL.so.1.1.0"
fi

# Update dynamic linker cache to pick up overlay libraries
chroot "$BUILD_DIR" ldconfig

# Enable services from overlays
if [ -f "$BUILD_DIR/etc/systemd/system/weston.service" ]; then
    echo "Enabling Weston service..."
    chroot "$BUILD_DIR" systemctl enable weston
fi

echo "Overlay installation complete."