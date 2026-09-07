#!/bin/sh
# Stage 05 — weston
# Builds weston-imx from source inside the arm64 chroot (QEMU emulation) and
# stages the installed artifacts to $WESTON_STAGE via meson DESTDIR.
#
# Requires 03-vivante.sh to have run first (Vivante headers + pkg-config must
# be present in $CHROOT_DIR/usr/).
#
# https://layers.openembedded.org/layerindex/recipe/402089/
set -e
. "$(dirname "$0")/common.sh"

if [ ! -x "$CHROOT_DIR/bin/sh" ]; then
    echo "Error: $CHROOT_DIR is not bootstrapped. Run stages 01–02 first."
    exit 1
fi

rm -rf \
    "$WESTON_STAGE" \
    "$CHROOT_DIR/tmp/weston-imx-src" \
    "$CHROOT_DIR/tmp/wayland-protocols-imx-src" \
    "$CHROOT_DIR/tmp/wp-imx-build" \
    "$CHROOT_DIR/tmp/weston-imx-build" \
    "$CHROOT_DIR/tmp/weston-stage" \
    /work/build/weston-imx-src \
    /work/build/wayland-protocols-imx-src

WESTON_REPO='https://github.com/nxp-imx/weston-imx.git'
WESTON_REF='lf-6.18.2-1.0.0'
WESTON_SRC='/work/build/weston-imx-src'
WESTON_BUILDTYPE="${WESTON_BUILDTYPE:-debugoptimized}"

WP_IMX_REPO='https://github.com/nxp-imx/wayland-protocols-imx.git'
WP_IMX_REF='wayland-protocols-imx-1.41'
WP_IMX_SRC='/work/build/wayland-protocols-imx-src'

# ── Clone on host (fast native git, cached) ───────────────────────────────────
if [ ! -d "$WESTON_SRC/.git" ]; then
    echo "[05-weston] Cloning weston-imx ${WESTON_REF}..."
    git clone --branch "$WESTON_REF" --depth 1 "$WESTON_REPO" "$WESTON_SRC"
else
    echo "[05-weston] Using cached weston-imx source at $WESTON_SRC"
fi

if [ ! -d "$WP_IMX_SRC/.git" ]; then
    echo "[05-weston] Cloning wayland-protocols-imx ${WP_IMX_REF}..."
    git clone --branch "$WP_IMX_REF" --depth 1 "$WP_IMX_REPO" "$WP_IMX_SRC"
else
    echo "[05-weston] Using cached wayland-protocols-imx source at $WP_IMX_SRC"
fi

# ── Stage sources inside chroot ───────────────────────────────────────────────
echo "[05-weston] Staging sources inside chroot..."
mkdir -p "$CHROOT_DIR/tmp"
rm -rf "$CHROOT_DIR/tmp/weston-imx-src"
cp -r "$WESTON_SRC" "$CHROOT_DIR/tmp/weston-imx-src"
rm -rf "$CHROOT_DIR/tmp/wayland-protocols-imx-src"
cp -r "$WP_IMX_SRC" "$CHROOT_DIR/tmp/wayland-protocols-imx-src"

# ── Mount chroot ──────────────────────────────────────────────────────────────
mount_chroot
trap 'umount_chroot' EXIT

# ── Install build dependencies inside arm64 chroot ───────────────────────────
echo "[05-weston] Installing build dependencies inside arm64 chroot (QEMU)..."
chroot "$CHROOT_DIR" /bin/sh <<'CHROOT_DEPS'
set -e
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 8.8.8.8" > /etc/resolv.conf
apt-get update
apt-get install -y \
    meson \
    ninja-build \
    patch \
    pkg-config \
    libdrm-dev \
    libpixman-1-dev \
    libxkbcommon-dev \
    libwayland-dev \
    libwayland-bin \
    wayland-protocols \
    libinput-dev \
    libseat-dev \
    libpam0g-dev \
    libsystemd-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libpng-dev \
    libjpeg-dev \
    libcairo2-dev \
    libwebp-dev \
    libpango1.0-dev \
    libdisplay-info-dev \
    glslang-tools
CHROOT_DEPS

# ── Patch libdrm headers (after libdrm-dev install) ───────────────────────────
# Debian's libdrm-dev is missing NXP-specific DRM format modifiers
# (DRM_FORMAT_MOD_AMPHION_TILED, DRM_FORMAT_MOD_VIVANTE_SUPER_TILED_FC).
# Must run after apt-get above, which would otherwise overwrite this file.
NXP_FOURCC='/work/kernel/include/uapi/drm/drm_fourcc.h'
if [ -f "$NXP_FOURCC" ]; then
    echo "[05-weston] Patching chroot libdrm headers with NXP kernel version..."
    cp "$NXP_FOURCC" "$CHROOT_DIR/usr/include/libdrm/drm_fourcc.h"
else
    echo "[05-weston] Warning: NXP kernel not found at $NXP_FOURCC; build may fail with missing DRM modifier constants."
fi

# ── Build and install inside arm64 chroot (DESTDIR) ──────────────────────────
echo "[05-weston] Building weston-imx inside arm64 chroot (QEMU) with buildtype=${WESTON_BUILDTYPE}..."
chroot "$CHROOT_DIR" /usr/bin/env WESTON_BUILDTYPE="$WESTON_BUILDTYPE" /bin/sh <<'CHROOT'
set -e
export DEBIAN_FRONTEND=noninteractive

# Some Vivante EGL stacks advertise EGL_EXT_platform_base but return NULL from
# eglGetProcAddress("eglGetPlatformDisplayEXT"). Use the linked core EGL 1.5
# entry points when the headers expose them, because falling back to
# eglGetDisplay() can make Vivante interpret Weston's GBM device pointer as a
# Wayland display and crash in wl_proxy_create_wrapper(). The same driver can
# also advertise optional EGL extensions while returning NULL for their query
# or feature entry points, so guard those probes instead of asserting.
perl -0pi -e '
s/\tif \(weston_check_egl_extension\(extensions, "EGL_EXT_device_query"\)\) \{\n\t\tgr->query_display_attrib =\n\t\t\t\(void \*\) eglGetProcAddress\("eglQueryDisplayAttribEXT"\);\n\t\tgr->query_device_string =\n\t\t\t\(void \*\) eglGetProcAddress\("eglQueryDeviceStringEXT"\);\n\t\tgr->has_device_query = true;\n\t\}/\tif (weston_check_egl_extension(extensions, "EGL_EXT_device_query")) {\n\t\tgr->query_display_attrib =\n\t\t\t(void *) eglGetProcAddress("eglQueryDisplayAttribEXT");\n\t\tgr->query_device_string =\n\t\t\t(void *) eglGetProcAddress("eglQueryDeviceStringEXT");\n\t\tif (gr->query_display_attrib && gr->query_device_string) {\n\t\t\tgr->has_device_query = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_EXT_device_query advertised but "\n\t\t\t\t   "required entry points are unavailable.\\n");\n\t\t}\n\t\}/s;
s/\tif \(weston_check_egl_extension\(extensions, "EGL_EXT_platform_base"\)\) \{\n\t\tgr->get_platform_display =\n\t\t\t\(void \*\) eglGetProcAddress\("eglGetPlatformDisplayEXT"\);\n\t\tgr->create_platform_window =\n\t\t\t\(void \*\) eglGetProcAddress\("eglCreatePlatformWindowSurfaceEXT"\);\n\t\tgr->has_platform_base = true;\n\t\} else \{/\tif (weston_check_egl_extension(extensions, "EGL_EXT_platform_base")) {\n\t\tgr->get_platform_display =\n\t\t\t(void *) eglGetProcAddress("eglGetPlatformDisplayEXT");\n\t\tgr->create_platform_window =\n\t\t\t(void *) eglGetProcAddress("eglCreatePlatformWindowSurfaceEXT");\n#ifdef EGL_VERSION_1_5\n\t\tif (!gr->get_platform_display)\n\t\t\tgr->get_platform_display =\n\t\t\t\t(PFNEGLGETPLATFORMDISPLAYEXTPROC) eglGetPlatformDisplay;\n\t\tif (!gr->create_platform_window)\n\t\t\tgr->create_platform_window =\n\t\t\t\t(PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC) eglCreatePlatformWindowSurface;\n#endif\n\t\tif (gr->get_platform_display) {\n\t\t\tgr->has_platform_base = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_EXT_platform_base advertised but "\n\t\t\t\t   "no eglGetPlatformDisplay entry point is available.\\n");\n\t\t}\n\t\} else {/s;
s/\tif \(weston_check_egl_extension\(extensions, "EGL_WL_bind_wayland_display"\)\)\n\t\tgr->has_bind_display = true;\n\tif \(gr->has_bind_display\) \{\n\t\tassert\(gr->bind_display\);\n\t\tassert\(gr->unbind_display\);\n\t\tassert\(gr->query_buffer\);\n\t\tret = gr->bind_display\(gr->egl_display, ec->wl_display\);\n\t\tif \(!ret\)\n\t\t\tgr->has_bind_display = false;\n\t\}/\tif (weston_check_egl_extension(extensions, "EGL_WL_bind_wayland_display")) {\n\t\tif (gr->bind_display && gr->unbind_display && gr->query_buffer) {\n\t\t\tgr->has_bind_display = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_WL_bind_wayland_display advertised but "\n\t\t\t\t   "required entry points are unavailable.\\n");\n\t\t}\n\t}\n\tif (gr->has_bind_display) {\n\t\tret = gr->bind_display(gr->egl_display, ec->wl_display);\n\t\tif (!ret)\n\t\t\tgr->has_bind_display = false;\n\t}/s;
s/\tif \(weston_check_egl_extension\(extensions, "EGL_KHR_partial_update"\)\) \{\n\t\tassert\(gr->set_damage_region\);\n\t\tgr->has_egl_partial_update = true;\n\t\}/\tif (weston_check_egl_extension(extensions, "EGL_KHR_partial_update")) {\n\t\tif (gr->set_damage_region) {\n\t\t\tgr->has_egl_partial_update = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_KHR_partial_update advertised but "\n\t\t\t\t   "required entry point is unavailable.\\n");\n\t\t}\n\t}/s;
s/\tfor \(i = 0; i < ARRAY_LENGTH\(swap_damage_ext_to_entrypoint\); i\+\+\) \{\n\t\tif \(weston_check_egl_extension\(extensions,\n\t\t\t\tswap_damage_ext_to_entrypoint\[i\]\.extension\)\) \{\n\t\t\tgr->swap_buffers_with_damage =\n\t\t\t\t\(void \*\) eglGetProcAddress\(\n\t\t\t\t\t\tswap_damage_ext_to_entrypoint\[i\]\.entrypoint\);\n\t\t\tassert\(gr->swap_buffers_with_damage\);\n\t\t\tbreak;\n\t\t\}\n\t\}/\tfor (i = 0; i < ARRAY_LENGTH(swap_damage_ext_to_entrypoint); i++) {\n\t\tif (weston_check_egl_extension(extensions,\n\t\t\t\tswap_damage_ext_to_entrypoint[i].extension)) {\n\t\t\tgr->swap_buffers_with_damage =\n\t\t\t\t(void *) eglGetProcAddress(\n\t\t\t\t\t\tswap_damage_ext_to_entrypoint[i].entrypoint);\n\t\t\tif (gr->swap_buffers_with_damage)\n\t\t\t\tbreak;\n\n\t\t\tweston_log("warning: %s advertised but required entry point %s "\n\t\t\t\t   "is unavailable.\\n",\n\t\t\t\t   swap_damage_ext_to_entrypoint[i].extension,\n\t\t\t\t   swap_damage_ext_to_entrypoint[i].entrypoint);\n\t\t}\n\t}/s;
s/\tif \(weston_check_egl_extension\(extensions,\n\t\t\t\t"EGL_EXT_image_dma_buf_import_modifiers"\)\) \{\n\t\tgr->query_dmabuf_formats =\n\t\t\t\(void \*\) eglGetProcAddress\("eglQueryDmaBufFormatsEXT"\);\n\t\tgr->query_dmabuf_modifiers =\n\t\t\t\(void \*\) eglGetProcAddress\("eglQueryDmaBufModifiersEXT"\);\n\t\tassert\(gr->query_dmabuf_formats\);\n\t\tassert\(gr->query_dmabuf_modifiers\);\n\t\tgr->has_dmabuf_import_modifiers = true;\n\t\}/\tif (weston_check_egl_extension(extensions,\n\t\t\t\t"EGL_EXT_image_dma_buf_import_modifiers")) {\n\t\tgr->query_dmabuf_formats =\n\t\t\t(void *) eglGetProcAddress("eglQueryDmaBufFormatsEXT");\n\t\tgr->query_dmabuf_modifiers =\n\t\t\t(void *) eglGetProcAddress("eglQueryDmaBufModifiersEXT");\n\t\tif (gr->query_dmabuf_formats && gr->query_dmabuf_modifiers) {\n\t\t\tgr->has_dmabuf_import_modifiers = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_EXT_image_dma_buf_import_modifiers "\n\t\t\t\t   "advertised but required entry points are unavailable.\\n");\n\t\t}\n\t}/s;
s/\tif \(weston_check_egl_extension\(extensions, "EGL_KHR_fence_sync"\) &&\n\t    weston_check_egl_extension\(extensions, "EGL_ANDROID_native_fence_sync"\)\) \{\n\t\tgr->create_sync =\n\t\t\t\(void \*\) eglGetProcAddress\("eglCreateSyncKHR"\);\n\t\tgr->destroy_sync =\n\t\t\t\(void \*\) eglGetProcAddress\("eglDestroySyncKHR"\);\n\t\tgr->dup_native_fence_fd =\n\t\t\t\(void \*\) eglGetProcAddress\("eglDupNativeFenceFDANDROID"\);\n\t\tassert\(gr->create_sync\);\n\t\tassert\(gr->destroy_sync\);\n\t\tassert\(gr->dup_native_fence_fd\);\n\t\tgr->has_native_fence_sync = true;\n\t\} else \{/\tif (weston_check_egl_extension(extensions, "EGL_KHR_fence_sync") &&\n\t    weston_check_egl_extension(extensions, "EGL_ANDROID_native_fence_sync")) {\n\t\tgr->create_sync =\n\t\t\t(void *) eglGetProcAddress("eglCreateSyncKHR");\n\t\tgr->destroy_sync =\n\t\t\t(void *) eglGetProcAddress("eglDestroySyncKHR");\n\t\tgr->dup_native_fence_fd =\n\t\t\t(void *) eglGetProcAddress("eglDupNativeFenceFDANDROID");\n\t\tif (gr->create_sync && gr->destroy_sync &&\n\t\t    gr->dup_native_fence_fd) {\n\t\t\tgr->has_native_fence_sync = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_ANDROID_native_fence_sync advertised "\n\t\t\t\t   "but required entry points are unavailable.\\n");\n\t\t}\n\t} else {/s;
s/\tif \(weston_check_egl_extension\(extensions, "EGL_KHR_wait_sync"\)\) \{\n\t\tgr->wait_sync = \(void \*\) eglGetProcAddress\("eglWaitSyncKHR"\);\n\t\tassert\(gr->wait_sync\);\n\t\tgr->has_wait_sync = true;\n\t\} else \{/\tif (weston_check_egl_extension(extensions, "EGL_KHR_wait_sync")) {\n\t\tgr->wait_sync = (void *) eglGetProcAddress("eglWaitSyncKHR");\n\t\tif (gr->wait_sync) {\n\t\t\tgr->has_wait_sync = true;\n\t\t} else {\n\t\t\tweston_log("warning: EGL_KHR_wait_sync advertised but required "\n\t\t\t\t   "entry point is unavailable.\\n");\n\t\t}\n\t} else {/s;
' /tmp/weston-imx-src/libweston/renderer-gl/egl-glue.c

grep -q 'if (gr->query_display_attrib && gr->query_device_string)' /tmp/weston-imx-src/libweston/renderer-gl/egl-glue.c
grep -q 'if (gr->set_damage_region)' /tmp/weston-imx-src/libweston/renderer-gl/egl-glue.c
grep -q 'if (gr->query_dmabuf_formats && gr->query_dmabuf_modifiers)' /tmp/weston-imx-src/libweston/renderer-gl/egl-glue.c
grep -q 'if (gr->create_sync && gr->destroy_sync &&' /tmp/weston-imx-src/libweston/renderer-gl/egl-glue.c
grep -q 'if (gr->wait_sync)' /tmp/weston-imx-src/libweston/renderer-gl/egl-glue.c

# Build and install wayland-protocols-imx (NXP fork) to provide the
# hdr10-metadata-unstable-v1.xml protocol required by weston-imx.
# Installed directly into the chroot (not DESTDIR'd) since it's a build dep.
meson setup /tmp/wp-imx-build /tmp/wayland-protocols-imx-src --prefix=/usr
ninja -C /tmp/wp-imx-build install
rm -rf /tmp/wayland-protocols-imx-src /tmp/wp-imx-build

# Configure weston-imx.
# Vivante EGL/GLES/GBM .pc files are in /usr/lib/aarch64-linux-gnu/pkgconfig
# (installed by 03-vivante.sh), so no PKG_CONFIG_PATH override is needed.
# Do NOT install libegl-dev / libgles2-dev / libgbm-dev — Vivante .pc files
# take priority and Mesa's would conflict.
rm -rf /tmp/weston-imx-build
meson setup /tmp/weston-imx-build /tmp/weston-imx-src \
    --prefix=/usr \
    --buildtype="$WESTON_BUILDTYPE" \
    -Dstrip=false \
    -Db_ndebug=false \
    -Dbackend-drm=true \
    -Dbackend-wayland=false \
    -Dbackend-x11=false \
    -Dbackend-headless=false \
    -Dbackend-pipewire=false \
    -Dbackend-rdp=false \
    -Dbackend-vnc=false \
    -Dbackend-drm-screencast-vaapi=false \
    -Dscreenshare=false \
    -Drenderer-gl=true \
    -Drenderer-g2d=false \
    -Dxwayland=false \
    -Dremoting=false \
    -Dpipewire=false \
    -Dcolor-management-lcms=false \
    -Dsimple-clients=[] \
    -Ddemo-clients=false \
    -Dtest-junit-xml=false \
    -Ddoc=false \
    -Dtools=terminal

ninja -C /tmp/weston-imx-build

# Install to DESTDIR so artifacts can be extracted to the host staging dir.
DESTDIR=/tmp/weston-stage ninja -C /tmp/weston-imx-build install

rm -rf /tmp/weston-imx-src /tmp/weston-imx-build

# Restore the systemd resolv.conf symlink for the final system.
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
CHROOT

# ── Extract DESTDIR output to host staging dir ────────────────────────────────
echo "[05-weston] Extracting weston artifacts to $WESTON_STAGE..."
mkdir -p "$WESTON_STAGE"
cp -a "$CHROOT_DIR/tmp/weston-stage/." "$WESTON_STAGE/"
rm -rf "$CHROOT_DIR/tmp/weston-stage"

# ── Write weston systemd service to staging dir ───────────────────────────────
# systemctl enable runs in 06-merge.sh once weston.service is in the final rootfs.
echo "[05-weston] Writing weston.service to staging dir..."
mkdir -p "$WESTON_STAGE/etc/systemd/system"
cat > "$WESTON_STAGE/etc/systemd/system/weston.service" <<'SERVICE'
[Unit]
Description=Weston Wayland Compositor
After=systemd-logind.service seatd.service
Wants=systemd-logind.service seatd.service

[Service]
Type=simple
User=rfnm
PAMName=login
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=wayland
Environment=LIBSEAT_BACKEND=seatd
Environment=SEATD_SOCK=/run/seatd.sock
ExecStartPre=+/bin/mkdir -p /run/user/1000
ExecStartPre=+/bin/chown rfnm:rfnm /run/user/1000
ExecStartPre=+/bin/chmod 700 /run/user/1000
ExecStart=/usr/bin/weston --backend=drm-backend.so --socket=wayland-0 --idle-time=0 --log=/tmp/weston-service.log
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
SERVICE

echo "[05-weston] weston-imx ${WESTON_REF} staged at ${WESTON_STAGE}."
