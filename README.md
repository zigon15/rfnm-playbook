# RFNM Playbook - Build System for iMX8MP

Build a bootable Debian-based Linux system for RFNM devices using Podman containerization.

## What This Builds

- **ARM Trusted Firmware (ATF)** - Low-level firmware for ARM processors
- **U-Boot** - Universal bootloader configured for NXP iMX8MP
- **Linux Kernel 6.1+** - With RFNM-specific patches and drivers
- **Debian 12 (Bookworm)** - ARM64 root filesystem
- **RFNM Drivers** - LA9310 driver and librfnm hardware library

## Prerequisites

**Host System:**
- Linux (Ubuntu 22.04+, Fedora 38+, or similar)
- Podman installed (`sudo apt install podman` or `sudo dnf install podman`)
- ~20GB free disk space (3GB container + 15GB build artifacts)
- Root access via `sudo` (required for SD card operations)

**Target Hardware:**
- SD card (4GB minimum, 8GB+ recommended for development)
- RFNM device with iMX8MP processor and SD card boot support
- Serial console adapter (USB-TTL, 115200 baud, 8N1) for debugging

## Quick Start - Build and Flash SD Card

The standard workflow for creating a bootable SD card:

```bash
cd build/podman

# 1. Build the container image (one-time setup, ~10 minutes)
./buildContainer.sh
# What it does: Creates Ubuntu 25.10 container with ARM64 cross-compilation tools

# 2. Copy container to root's Podman namespace (required for device access)
./copyContainerRoot.sh
# What it does: Exports/imports container so it can be run as root for SD card flashing

# 3. Run container with SD card device mapped
sudo ./runContainer.sh /dev/sdX
# Parameters: Replace 'sdX' with your actual SD card device (check with: lsblk or dmesg | tail)
# What it does: Launches container with device access and mounts scripts/build directories
# IMPORTANT: Double-check device name! Wrong device = data loss!

# Inside the container, run these commands:

# 4. Build all components (ATF, U-Boot, Kernel, Debian rootfs - ~1.5-2 hours)
./buildLinux.sh
# What it does:
#   - Clones 6 git repositories (kernel, u-boot, drivers, librfnm, ATF, etc.)
#   - Checks out known-good commits (prevents build failures)
#   - Downloads NXP firmware blobs (~200MB)
#   - Builds ARM Trusted Firmware, U-Boot bootloader, and Linux kernel
#   - Creates Debian 12 ARM64 root filesystem
#   - Installs kernel modules and firmware into rootfs

# 5. Flash to SD card (10-20 minutes)
./flashSD.sh
# What it does:
#   - Validates SD card and build artifacts
#   - Partitions SD card with proper layout (8MB offset, boot, rootfs)
#   - Installs U-Boot bootloader at 32KB offset
#   - Copies Linux kernel and device tree to boot partition
#   - Copies entire Debian rootfs to root partition
#   - Generates U-Boot boot script for automatic booting
```

## Alternative Workflow - Build Without SD Card Flashing

If you want to build without an SD card present (useful for development or creating disk images):

```bash
cd build/podman
./buildContainer.sh
./copyContainerRoot.sh

# Run without device mapping (no SD card needed)
sudo ./runContainer.sh

# Inside container:
./buildLinux.sh
# Build artifacts are now ready in ./build/ directory
```

You can later:
- Create a distributable disk image: `./createImg.sh /path/to/image.img 4`
- Flash a pre-built image: `./flashImgToSD.sh /path/to/image.img /dev/sdX` (much faster than full build)
- Manually copy files for customization

## After Flashing

1. **Insert SD card** into your RFNM device
2. **Set boot switches** to SD card mode (see [docs/device.md](docs/device.md) for details)
3. **Connect serial console** (115200 baud, 8N1) if available, or wait for network
4. **Power on the device**
5. **Default credentials:** `root` (no password initially)
6. **Find on network:** `sudo arp-scan --localnet | grep -iE "nxp|freescale"`

## Additional Commands

Inside the container, additional helper scripts are available:

- `./checkSD.sh` - Verify SD card contents and filesystem integrity
- `./createImg.sh [output_image] [size_gb]` - Create a flashable disk image file
- `./flashImgToSD.sh [image_file] [device]` - Flash pre-built image to SD card (faster than full build+flash)

## Documentation

- **[build/podman/README.md](build/podman/README.md)** - Comprehensive build documentation with detailed script explanations, troubleshooting, and advanced usage
- **[docs/device.md](docs/device.md)** - Device-specific information, networking, and post-boot setup
- **[build/manual/README.md](build/manual/README.md)** - Manual build process without Podman

## Build System Architecture

The build process uses Podman containerization to ensure a consistent cross-compilation environment:

1. `buildContainer.sh` creates an isolated Ubuntu container with ARM64 tools
2. `copyContainerRoot.sh` enables privileged operations (SD card access)
3. `runContainer.sh` launches the container with device and script mounting
4. Inside the container, `buildLinux.sh` orchestrates the build:
   - Clones and patches source repositories
   - Cross-compiles all components for ARM64
   - Creates a complete bootable system
5. `flashSD.sh` writes the system to SD card with proper bootloader configuration

See [build/podman/README.md](build/podman/README.md) for detailed explanations of each step.

## Troubleshooting Quick Reference

**Build fails:** See troubleshooting section in [build/podman/README.md](build/podman/README.md#troubleshooting)

**Container won't start:** Verify Podman is installed and running: `systemctl --user start podman`

**SD card not detected:** Check with `lsblk` and `dmesg | tail -20`

**Won't boot after flashing:**
- Verify serial console output to check for boot errors
- Ensure boot switches are set to SD mode
- Try re-flashing the SD card completely

**More issues?** Check the comprehensive troubleshooting guide in [build/podman/README.md](build/podman/README.md)

## For Manual Build (No Podman)

If you prefer not to use containerization, see [build/manual/README.md](build/manual/README.md). Note: Manual builds are more error-prone due to environment differences and missing patches.