# RFNM Build (use `build.py`)

Use the container scripts to enter the build environment, then use `build.py` for nearly everything (build, partial rebuild, and flashing).

## Quick Start

Optional but recommended on desktop Linux to avoid automount races while flashing:

```bash
gsettings set org.gnome.desktop.media-handling automount false
gsettings set org.gnome.desktop.media-handling automount-open false
```

```bash
cd build
sudo ./buildContainer.sh      # one-time or after Containerfile changes
sudo ./runContainer.sh

# inside the container:
./build.py
```

`build.py` provides:
- full build or partial rebuild
- rootfs variant selection (`weston`, `desktop`, `base`)
- staged rootfs rebuild for Weston
- optional flashing (SD, or SD+USB split)

## Recommended Workflow

- For normal development: run `./build.py` and choose **Partial** for only what changed.
- For clean reproducible builds: run `./build.py` and choose **Full build**.
- For flashing pre-built artifacts only: run `./build.py` and choose **Flash**.

## Useful Scripts (when not using `build.py`)

- `./flashSD.sh` - flash full system to SD
- `./flashSD_UBootUsb.sh` + `./flashUSB_Linux.sh` - SD bootloader + USB kernel/rootfs
- `./createImg.sh /work/build/rfnm-image.img 4` - create image from current artifacts
- `./flashSD_Img.sh /work/build/rfnm-image.img /dev/sdX` - write image to SD

## Main Artifacts

After a successful build, outputs are under `/work/build/`, including:
- `imx8mp-uboot/flash.bin`
- `kernel/arch/arm64/boot/Image`
- `kernel/arch/arm64/boot/dts/freescale/imx8mp-rfnm.dtb`
- `debian/` (rootfs)

## References

- Top-level project docs: [../README.md](../README.md)
- Device notes: [../../docs/device.md](../../docs/device.md)
  