# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RFNM Playbook is a build system for creating bootable Debian-based Linux systems for RFNM devices (based on NXP iMX8MP). The system uses Podman containerization to provide a consistent cross-compilation environment. It orchestrates building multiple components: ARM Trusted Firmware (ATF), U-Boot bootloader, Linux Kernel 6.1+, Debian 12 root filesystem, and RFNM-specific drivers (LA9310 driver and librfnm).

### RFNM Device Purpose

RFNM is an SBC (Single Board Computer) Software-Defined Radio (SDR) platform. Once booted with this image, the RFNM device:
- Streams IQ (in-phase/quadrature) samples to a laptop or external computer via **USB 3.0 USB-C** at high bandwidth
- Runs a Linux kernel with the LA9310 baseband processor driver (enabled in `scripts/la9310-driver/`)
- Uses librfnm as the hardware abstraction library for accessing RF frontend and baseband controls
- Provides full RF capability with real-time sample streaming for software-defined radio applications

The USB 3.0 USB-C connection provides sufficient bandwidth for high-rate IQ sample streaming while also powering the device. The kernel configuration and LA9310 driver are critical to enabling this data path.

### Boot Sequence and Runtime

When the device boots from SD card, the complete initialization stack executes:

1. **Bootloader Stage** (U-Boot SPL + U-Boot)
   - ARM Trusted Firmware (ATF) initializes CPU and memory
   - U-Boot loads kernel and device tree from boot partition

2. **Kernel Boot** (Linux 5.15.71-rt51 or later)
   - Debian 12 root filesystem mounts from SD card partition 3
   - Real-time kernel patches enable deterministic timing for baseband processing
   - Stack initialization disabled (`CONFIG_INIT_STACK_NONE`) for USB performance

3. **RFNM Hardware Initialization** (LA9310 driver)
   - LA9310 baseband processor firmware loads and boots via PCIe
   - FreeRTOS firmware validates with handshake
   - VSPA (vector signal processor) firmware loads for RF signal processing
   - MSI interrupts allocated for baseband-to-host communication

4. **USB Gadget Stack** (rfnm_usb, rfnm_usb_function modules)
   - Configures USB 3.0 device controller for super-speed (up to 5Gbps)
   - Registers rfnm_usb gadget function for IQ sample streaming
   - rfnm_usb_boost variant for enhanced performance

5. **RF Frontend** (Lime/Granita/Breakout daughterboards)
   - Si5510 oscillator clock tree initialized
   - Daughterboards detected on I2C and SPI busses
   - Per-slot RF hardware (Lime LMS7002M SDR, oscillators, amplifiers) configured

6. **System Services** (systemd)
   - NETCONF/YANG management stack (sysrepod, netopeer2-server)
   - sysrepo configuration database for RF parameter persistence
   - SSH access available after network configuration

The resulting system streams multi-MHz bandwidth IQ samples in real-time to connected applications.

## Common Development Workflows

### Building and Flashing an SD Card

Standard workflow to create a bootable SD card:

```bash
cd build/podman

# One-time setup: build container with cross-compilation tools
./buildContainer.sh

# Copy container to root's Podman namespace (required for privileged device access)
./copyContainerRoot.sh

# Run container with SD card device mapped (replace sdX with actual device)
sudo ./runContainer.sh /dev/sdX

# Inside the container, build all components (ATF, U-Boot, Kernel, Debian)
./buildLinux.sh

# Flash the SD card
./flashSD.sh
```

### Building Without SD Card (Development)

For development or creating disk images without an SD card present:

```bash
cd build/podman
./buildContainer.sh
./copyContainerRoot.sh
sudo ./runContainer.sh

# Inside container:
./buildLinux.sh

# Build artifacts available in ./build/ directory
# Create a flashable image: ./createImg.sh /path/to/image.img 4
# Flash later: ./flashImgToSD.sh /path/to/image.img /dev/sdX
```

## Build System Architecture

The build process is orchestrated through shell scripts that coordinate multiple build components:

1. **`buildContainer.sh`** - Creates a Debian Trixie container with ARM64 cross-compilation tools (gcc-arm-none-eabi, crossbuild-essential-arm64, etc.)

2. **`copyContainerRoot.sh`** - Exports and imports container to root's Podman namespace, enabling privileged operations needed for SD card access

3. **`runContainer.sh`** - Launches container with mounts for build scripts and device mappings. Environment variable `FLASH_DEVICE` can be used instead of positional argument.

4. **`buildLinux.sh`** (inside container) - Main orchestration script that:
   - Clones 6 git repositories: imx8mp-kernel, imx8mp-uboot, la9310-driver, la9310-freertos, imx-atf, librfnm
   - Checks out known-good commits to prevent build failures
   - Downloads NXP firmware blobs (~200MB)
   - Invokes sub-scripts for ATF, U-Boot, kernel, LA9310 firmware, LA9310 driver, and Debian rootfs

5. **Helper Scripts** (inside container):
   - `scripts/flashSD.sh` - Partitions and flashes SD card with U-Boot, kernel, and rootfs
   - `scripts/createImg.sh` - Creates a flashable disk image file
   - `scripts/flashImgToSD.sh` - Flashes a pre-built image to SD card
   - `scripts/checkSD.sh` - Verifies SD card contents and filesystem integrity

## Key Component Build Scripts

Each component has dedicated build scripts in `scripts/` subdirectories:

- **`scripts/git/`** - Repository management (cloneRepos.sh, checkoutGoodCommits.sh, getFirmware.sh)
- **`scripts/uboot/`** - U-Boot and ARM Trusted Firmware builds (buildATF.sh, build.sh)
- **`scripts/kernel/`** - Linux kernel configuration and build (build.sh applies patches and config)
- **`scripts/la9310-rtos/`** - LA9310 RTOS firmware build
- **`scripts/la9310-driver/`** - LA9310 driver kernel module build
- **`scripts/debian/`** - Debian 12 ARM64 rootfs creation and customization

## Important Implementation Details

### Kernel Configuration

The kernel build (`scripts/kernel/build.sh`) applies critical modifications:
- Uses `imx8mp_rfnm_defconfig` device tree configuration
- Disables proprietary MXC GPU VIV driver, enables open-source etnaviv DRM
- **Enables `CONFIG_INIT_STACK_NONE`** (disables kernel stack variable zeroing) to prevent USB buffer allocation failures during high-speed IQ sample streaming
- Additional RFNM-specific modules can be enabled via config

#### Stack Zeroing Configuration (Critical)

The `CONFIG_INIT_STACK_NONE` setting is important for USB performance because:
- Kernel stack variable initialization consumes memory bandwidth and CPU cycles
- High-bandwidth USB 3.0 IQ streaming (multi-Gbps) can be starved by this overhead
- Disabling automatic stack zeroing frees resources for real-time baseband processing

**Implementation Note**: `CONFIG_INIT_STACK_NONE` is part of a Kconfig "choice" block (mutually exclusive options). To properly set it:
```bash
scripts/config --disable CONFIG_INIT_STACK_ALL_ZERO
scripts/config --enable CONFIG_INIT_STACK_NONE
```
Both commands are necessary - disabling alone leaves the choice block empty, causing `make olddefconfig` to re-enable the default. Verify with: `grep INIT_STACK .config` should show only `CONFIG_INIT_STACK_NONE=y`

### SD Card Flashing

The `flashSD.sh` script:
- Validates SD card and build artifacts before touching the device
- Partitions with 8MB offset to comply with iMX8MP requirements
- Installs U-Boot at 32KB offset
- Creates separate boot and root partitions
- Generates U-Boot boot script for automatic booting
- Requires root privileges and validates device existence

### Repository Sources

All components are cloned from RFNM and NXP GitHub repositories:
- RFNM repositories: https://github.com/rfnm/
- NXP repositories: https://github.com/nxp-imx/

Known-good commits are checked out to prevent build failures caused by upstream changes.

## Containerfile Configuration

Located at `build/podman/Containerfile`. Uses Debian Trixie as base with:
- ARM64 cross-compilation toolchain (crossbuild-essential-arm64)
- Build tools: gcc-arm-none-eabi, binutils-arm-none-eabi, cmake
- Kernel build dependencies: bison, flex, libssl-dev, libncurses-dev, device-tree-compiler
- Utilities: git, parted, fdisk, dosfstools, rsync, u-boot-tools
- Emulation: qemu-user-static, binfmt-support for running ARM binaries

## Device Integration

After flashing, the RFNM device boots from SD card (requires setting boot switches). Post-boot configuration:
- Default credentials: `root` (no password initially)
- Network discovery: `sudo arp-scan --localnet | grep -iE "nxp|freescale|00:04:9f"`
- SSH access: `ssh root@<device-ip>`
- USB-A power can be enabled via: `/rfnm/scripts/enable_usb-a`

See `docs/device.md` for device-specific information and networking setup.

## Build Paths and Environment

Inside the container, work directory structure:
- `/work/build/` - All build artifacts (U-Boot, kernel, rootfs, ATF)
- `/work/scripts/` - Build scripts (git, uboot, kernel, la9310-driver, la9310-rtos, debian)
- Key artifacts:
  - `/work/build/imx8mp-uboot/flash.bin` - U-Boot binary
  - `/work/build/imx8mp-kernel/arch/arm64/boot/Image` - Kernel
  - `/work/build/imx8mp-kernel/arch/arm64/boot/dts/freescale/imx8mp-rfnm.dtb` - Device tree
  - `/work/build/debian/` - Root filesystem

## Troubleshooting Notes

- Build failures often relate to environment differences; containerization ensures consistency
- SD card device verification is critical before flashing—double-check with `lsblk`
- Kernel configuration issues: See `scripts/kernel/build.sh` for device-specific settings
- Repository cloning uses shallow clones for faster downloads (can disable `--depth` if needed)
- Firmware download failures: Check NXP firmware availability and network connectivity

