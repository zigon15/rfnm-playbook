# Building Bootable SD Card for RFNM (Podman Method)

Build a bootable Linux system for RFNM devices using Podman containerization.

## Prerequisites

- **Linux** with Podman 4.0+ installed
- **~20GB free disk space** (3GB container, 15GB artifacts)
- **2 hours** for first build (30-45 minutes for incremental builds)
- **Root access** via sudo for SD card operations
- **SD card** (4GB minimum, 8GB+ recommended)

## Quick Start

It is best to disable automount to stop the host os screwing up the flash sd script!!
```
  gsettings set org.gnome.desktop.media-handling automount false                                                                
  gsettings set org.gnome.desktop.media-handling automount-open false 
```

### Build and Flash Workflow

```bash
cd build/podman

# 1. Build container (one-time setup, ~10 minutes)
./buildContainer.sh

# 2. Copy to root's Podman (required for SD card access)
./copyContainerRoot.sh

# 3. Run container with SD card device
# IMPORTANT: Verify device name first with: lsblk
sudo ./runContainer.sh /dev/sdX   # Replace sdX with your SD card

# Inside container:

# 4. Build everything (ATF, U-Boot, Kernel, Debian rootfs - ~1.5-2 hours)
./buildLinux.sh

# 5. Flash to SD card (~10-20 minutes)
./flashSD.sh

# Exit container
exit
```

### Alternative: Build Only (No SD Card)

```bash
cd build/podman
./buildContainer.sh
./copyContainerRoot.sh
sudo ./runContainer.sh  # No device parameter
./buildLinux.sh
exit
```

### Create Distributable Image

```bash
# Inside container (after buildLinux.sh):
./createImg.sh /work/build/rfnm-image.img 4
# Creates 4GB image file, then flash to multiple cards:
./flashImgToSD.sh /work/build/rfnm-image.img /dev/sdX
```

## Scripts Overview

### Host Scripts

- **`buildContainer.sh`** - Builds Ubuntu 25.10 container with ARM64 cross-compilation tools (~10 min, one-time)
- **`copyContainerRoot.sh`** - Copies container to root's Podman namespace for privileged operations (~30 sec)
- **`runContainer.sh [device]`** - Launches container with optional SD card device mapping

### Container Scripts

- **`buildLinux.sh`** - Clones repos, builds ATF/U-Boot/Kernel, creates Debian rootfs (~1.5-2 hours)
  - Clones 6 repositories (kernel, u-boot, ATF, drivers, librfnm)
  - Checks out known-good commits
  - Downloads NXP firmware blobs
  - Builds everything needed for bootable system

- **`flashSD.sh`** - Partitions SD card and writes bootloader, kernel, and rootfs (~10-20 minutes)
  - Validates build artifacts and target device
  - Safety checks to prevent data loss
  - Creates partition table (8MB offset, FAT32 boot, ext4 rootfs)
  - Flashes U-Boot at 32KB offset
  - Copies kernel and Debian rootfs

- **`checkSD.sh`** - Verifies SD card contents and filesystem integrity
  - Edit device path in script before use (currently hardcoded to /dev/sdb)

- **`createImg.sh [output] [size]`** - Creates distributable disk image file (default: 4GB)
  - Creates sparse image, useful for distributing and flashing multiple cards

- **`flashImgToSD.sh [image] [device]`** - Flashes pre-built image to SD card (5-10 minutes, much faster than full build)

## Build Artifacts

After `buildLinux.sh` completes, artifacts are in `./build/`:

```
build/
├── imx8mp-uboot/flash.bin       # U-Boot bootloader (~1.5MB)
├── imx8mp-kernel/
│   ├── arch/arm64/boot/Image    # Kernel binary (~30MB)
│   └── dts/freescale/imx8mp-rfnm.dtb
├── imx-atf/build/imx8mp/release/bl31.bin
├── debian/                       # Complete Debian 12 ARM64 rootfs (~1-2GB)
├── firmware/                     # NXP firmware blobs
├── la9310-driver/
├── la9310-freertos/
└── librfnm/
```

## Troubleshooting

**Container won't build:**
- Verify Podman is running: `systemctl --user start podman.socket`
- Ensure internet connection for downloading base image

**buildLinux.sh fails during git clone:**
- Check internet connection: `ping github.com`
- May be rate-limited - wait 1 hour or use GitHub token

**"No space left on device":**
- Check available space: `df -h`
- Ensure 20GB free before building
- Clean old builds if needed

**Wrong SD card flashed:**
- Always verify device with `lsblk` before running flashSD.sh
- Script will warn if device looks like system drive
- Type "yes" to confirm

**Won't boot after flashing:**
1. Check serial console output (115200 baud, 8N1)
2. Verify RFNM boot switches set to SD mode
3. Verify boot partition has: Image, imx8mp-rfnm.dtb, boot.scr
4. Try re-flashing SD card completely

**Boots but network not working:**
- Check kernel loaded network driver: `lsmod | grep -i eth`
- Verify firmware installed: `ls /lib/firmware/`
- Check kernel includes network support in defconfig

## Advanced Usage

### Rebuild Individual Components

```bash
# Rebuild only kernel
cd /work/scripts/kernel
./clean.sh
./build.sh
cd /work/scripts/debian
./installKernelModules.sh
```

### Custom Kernel Configuration

```bash
cd /work/build/imx8mp-kernel
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

### Modify Debian Rootfs

```bash
cd /work/build/debian
sudo cp /usr/bin/qemu-aarch64-static usr/bin/
sudo chroot . /bin/bash
# Make changes...
exit
```

### Compress Image for Distribution

```bash
cd /work/build
xz -z -9 -v rfnm-image.img
# Creates rfnm-image.img.xz (~50% smaller for distribution)
xz -d rfnm-image.img.xz  # Decompress before flashing
```

## FAQ

**Q: Build is slow, can I speed it up?**
A: Parallel builds use more CPU. Try `make -j$(nproc)` in kernel builds. More RAM and CPU cores help significantly.

**Q: Can I use different kernel commits?**
A: Edit `/work/scripts/git/checkoutGoodCommits.sh` to use different commits, but be aware this may cause build failures.

**Q: How do I add packages to the system?**
A: Either modify debian build script before building, or chroot into `/work/build/debian/` and install packages.

**Q: What if I want to update just the kernel?**
A: Rebuild kernel, reinstall modules to rootfs, then re-run `flashSD.sh` to write updated components.

**Q: Can I use Docker instead of Podman?**
A: Mostly yes - replace `podman` with `docker` in scripts, but copyContainerRoot behavior differs for root access.

## Support
- Check [../README.md](../README.md) for high-level overview
- See [../../docs/device.md](../../docs/device.md) for device-specific info
- Post issues on GitHub: [rfnm/rfnm-playbook](https://github.com/rfnm/rfnm-playbook)

## What Gets Built
1. **ARM Trusted Firmware (ATF)** - Low-level secure boot firmware
2. **U-Boot** - Universal bootloader for iMX8MP
3. **Linux Kernel 6.1+** - ARM64 kernel with RFNM patches
4. **Debian 12 (Bookworm)** - Complete ARM64 root filesystem
5. **RFNM Drivers** - LA9310 hardware driver and librfnm library
  