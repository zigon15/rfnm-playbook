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

# This is the creators succesfull kernel boot log with GNU radio streaming initalized
U-Boot SPL 2022.04-uboot_v2022.04-2.5.0+gbc9e54edb2 (May 08 2024 - 22:14:19 +0200)
DDRINFO: start DRAM init
DDRINFO: DRAM rate 4000MTS
DDRINFO:ddrphy calibration done
DDRINFO: ddrmix config done
SEC0:  RNG instantiated
Normal Boot
Trying to boot from BOOTROM
Boot Stage: Primary boot
image offset 0x8000, pagesize 0x200, ivt offset 0x0
NOTICE:  BL31: v2.6(release):automotive-13.0.0_1.1.0-0-g3c1583ba0
NOTICE:  BL31: Built : 12:28:08, Mar 24 2024


U-Boot 2022.04-uboot_v2022.04-2.5.0+gbc9e54edb2 (May 08 2024 - 22:14:19 +0200)

CPU:   i.MX8MP Lite[4] rev1.1 at 1600MHz
CPU:   Industrial temperature grade (-40C to 105C) at 42C
Reset cause: POR
Model: NXP i.MX8MPlus LPDDR4 EVK board
DRAM:  4 GiB
Done pwr en init
Core:  73 devices, 21 uclasses, devicetree: separate
MMC:   FSL_SDHC: 1, FSL_SDHC: 2
Loading Environment from MMC... OK
Fail to setup video link
In:    serial
Out:   serial
Err:   serial
SEC0:  RNG instantiated

 BuildInfo:
  - ATF 3c1583b

flash target is MMC:2
Net:   eth1: ethernet@30bf0000
Fastboot: Normal
Normal Boot
Hit any key to stop autoboot:  0 
MMC: no card present
Couldn't find partition mmc 1:1
MMC: no card present
Couldn't find partition mmc 1:2
Booting normal partition
58771 bytes read in 1 ms (56 MiB/s)
33366528 bytes read in 111 ms (286.7 MiB/s)
## Flattened Device Tree blob at 43000000
   Booting using the fdt blob at 0x43000000
ERROR: reserving fdt memory region failed (addr=7e0000 size=20000 flags=4)
ERROR: reserving fdt memory region failed (addr=800000 size=20000 flags=4)
ERROR: reserving fdt memory region failed (addr=55000000 size=8000 flags=4)
ERROR: reserving fdt memory region failed (addr=55008000 size=8000 flags=4)
ERROR: reserving fdt memory region failed (addr=55400000 size=100000 flags=4)
ERROR: reserving fdt memory region failed (addr=550ff000 size=1000 flags=4)
   Using Device Tree in place at 0000000043000000, end 0000000043011592
Modify /vpu_g1@38300000:status disabled
Modify /vpu_g2@38310000:status disabled
Modify /vpu_vc8000e@38320000:status disabled
Modify /vipsi@38500000:status disabled
Modify /soc@0/bus@32c00000/camera/isp@32e10000:status disabled
Modify /soc@0/bus@32c00000/camera/isp@32e20000:status disabled
Modify /dsp@3b6e8000:status disabled

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x410fd034]
[    0.000000] Linux version 5.15.71-rt51 (davide@imx-vm) (aarch64-poky-linux-gcc (GCC) 11.3.0, GNU ld (GNU Binutils) 2.38.20220708) #27 SMP PREEMPT_RT Sun Jun 23 11:53:12 CEST 2024
[    0.000000] Machine model: RFNM imx8mp
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: OVERLAP DETECTED!
[    0.000000] dsp@92400000 (0x0000000092400000--0x0000000093400000) overlaps with la93@92400000 (0x0000000092400000--0x0000000096400000)
[    0.000000] OF: reserved mem: OVERLAP DETECTED!
[    0.000000] la93@92400000 (0x0000000092400000--0x0000000096400000) overlaps with dsp_reserved_heap (0x0000000093400000--0x00000000942f0000)
[    0.000000] Reserved memory: created CMA memory pool at 0x00000000c4000000, size 960 MiB
[    0.000000] OF: reserved mem: initialized node linux,cma, compatible id shared-dma-pool
[    0.000000] Reserved memory: created DMA memory pool at 0x0000000055400000, size 1 MiB
[    0.000000] OF: reserved mem: initialized node vdevbuffer@55400000, compatible id shared-dma-pool
[    0.000000] Reserved memory: created DMA memory pool at 0x0000000094300000, size 1 MiB
[    0.000000] OF: reserved mem: initialized node vdev0buffer@94300000, compatible id shared-dma-pool
[    0.000000] NUMA: No NUMA configuration found
[    0.000000] NUMA: Faking a node at [mem 0x0000000040000000-0x000000013fffffff]
[    0.000000] NUMA: NODE_DATA [mem 0x13f7d86c0-0x13f7dafff]
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000040000000-0x00000000ffffffff]
[    0.000000]   DMA32    empty
[    0.000000]   Normal   [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000040000000-0x0000000054ffffff]
[    0.000000]   node   0: [mem 0x0000000055000000-0x000000005500ffff]
[    0.000000]   node   0: [mem 0x0000000055010000-0x00000000550fefff]
[    0.000000]   node   0: [mem 0x00000000550ff000-0x00000000550fffff]
[    0.000000]   node   0: [mem 0x0000000055100000-0x00000000553fffff]
[    0.000000]   node   0: [mem 0x0000000055400000-0x00000000554fffff]
[    0.000000]   node   0: [mem 0x0000000055500000-0x000000007fffffff]
[    0.000000]   node   0: [mem 0x0000000080000000-0x0000000080ffffff]
[    0.000000]   node   0: [mem 0x0000000081000000-0x00000000923fffff]
[    0.000000]   node   0: [mem 0x0000000092400000-0x00000000963fffff]
[    0.000000]   node   0: [mem 0x0000000096400000-0x00000000a33fffff]
[    0.000000]   node   0: [mem 0x00000000a3400000-0x00000000a37fffff]
[    0.000000]   node   0: [mem 0x00000000a3800000-0x000000013fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000040000000-0x000000013fffffff]
[    0.000000] psci: probing for conduit method from DT.
[    0.000000] psci: PSCIv1.1 detected in firmware.
[    0.000000] psci: Using standard PSCI v0.2 function IDs
[    0.000000] psci: MIGRATE_INFO_TYPE not supported.
[    0.000000] psci: SMC Calling Convention v1.2
[    0.000000] percpu: Embedded 19 pages/cpu s40816 r8192 d28816 u77824
[    0.000000] Detected VIPT I-cache on CPU0
[    0.000000] CPU features: detected: GIC system register CPU interface
[    0.000000] CPU features: detected: ARM erratum 845719
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1032192
[    0.000000] Policy zone: Normal
[    0.000000] Kernel command line: console=ttymxc1,115200 root=/dev/mmcblk2p3 rootwait rw
[    0.000000] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
[    0.000000] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] software IO TLB: mapped [mem 0x00000000c0000000-0x00000000c4000000] (64MB)
[    0.000000] Memory: 2731316K/4194304K available (18944K kernel code, 2056K rwdata, 7796K rodata, 3648K init, 546K bss, 479948K reserved, 983040K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000] rcu:     RCU event tracing is enabled.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=256 to nr_cpu_ids=4.
[    0.000000] rcu:     RCU priority boosting: priority 1 delay 500 ms.
[    0.000000] rcu:     RCU_SOFTIRQ processing moved to rcuc kthreads.
[    0.000000]  No expedited grace period (rcu_normal_after_boot).
[    0.000000]  Trampoline variant of Tasks RCU enabled.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] GICv3: GIC: Using split EOI/Deactivate mode
[    0.000000] GICv3: 160 SPIs implemented
[    0.000000] GICv3: 0 Extended SPIs implemented
[    0.000000] GICv3: Distributor has no Range Selector support
[    0.000000] Root IRQ handler: gic_handle_irq
[    0.000000] GICv3: 16 PPIs implemented
[    0.000000] GICv3: CPU0: found redistributor 0 region 0:0x0000000038880000
[    0.000000] ITS: No ITS available, not enabling LPIs
[    0.000000] arch_timer: cp15 timer(s) running at 8.00MHz (phys).
[    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x1d854df40, max_idle_ns: 440795202120 ns
[    0.000000] sched_clock: 56 bits at 8MHz, resolution 125ns, wraps every 2199023255500ns
[    0.000339] Console: colour dummy device 80x25
[    0.000397] Calibrating delay loop (skipped), value calculated using timer frequency.. 16.00 BogoMIPS (lpj=32000)
[    0.000404] pid_max: default: 32768 minimum: 301
[    0.000450] LSM: Security Framework initializing
[    0.000520] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.000535] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.001808] rcu: Hierarchical SRCU implementation.
@�H�z}HcL�8���&[    0.003816] smp: Bringing up secondary CPUs ...
[    0.004378] Detected VIPT I-cache on CPU1
[    0.004399] GICv3: CPU1: found redistributor 1 region 0:0x00000000388a0000
[    0.004429] CPU1: Booted secondary processor 0x0000000001 [0x410fd034]
[    0.004953] Detected VIPT I-cache on CPU2
[    0.004968] GICv3: CPU2: found redistributor 2 region 0:0x00000000388c0000
[    0.004983] CPU2: Booted secondary processor 0x0000000002 [0x410fd034]
[    0.005452] Detected VIPT I-cache on CPU3
[    0.005465] GICv3: CPU3: found redistributor 3 region 0:0x00000000388e0000
[    0.005478] CPU3: Booted secondary processor 0x0000000003 [0x410fd034]
[    0.005525] smp: Brought up 1 node, 4 CPUs
[    0.005529] SMP: Total of 4 processors activated.
[    0.005532] CPU features: detected: 32-bit EL0 Support
[    0.005534] CPU features: detected: CRC32 instructions
[    0.011154] CPU: All CPU(s) started at EL2
[    0.011169] alternatives: patching kernel code
[    0.012390] devtmpfs: initialized
[    0.023062] KASLR disabled due to lack of seed
[    0.023233] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.023244] futex hash table entries: 1024 (order: 4, 65536 bytes, linear)
[    0.048113] pinctrl core: initialized pinctrl subsystem
[    0.048663] DMI not present or invalid.
[    0.049157] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.054222] DMA: preallocated 512 KiB GFP_KERNEL pool for atomic allocations
[    0.054503] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations
[    0.054818] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.054902] audit: initializing netlink subsys (disabled)
[    0.055089] audit: type=2000 audit(0.052:1): state=initialized audit_enabled=0 res=1
[    0.055717] thermal_sys: Registered thermal governor 'step_wise'
[    0.055720] thermal_sys: Registered thermal governor 'power_allocator'
[    0.056062] cpuidle: using governor menu
[    0.056238] hw-breakpoint: found 6 breakpoint and 4 watchpoint registers.
[    0.056297] ASID allocator initialised with 65536 entries
[    0.057153] Serial: AMBA PL011 UART driver
[    0.057217] imx mu driver is registered.
[    0.057238] imx rpmsg driver is registered.
[    0.065938] imx8mp-pinctrl 30330000.pinctrl: initialized IMX pinctrl driver
[    0.077684] platform 32fd8000.hdmi: Fixing up cyclic dependency with 32fc6000.lcd-controller
[    0.100942] HugeTLB registered 1.00 GiB page size, pre-allocated 0 pages
[    0.100950] HugeTLB registered 32.0 MiB page size, pre-allocated 0 pages
[    0.100953] HugeTLB registered 2.00 MiB page size, pre-allocated 0 pages
[    0.100956] HugeTLB registered 64.0 KiB page size, pre-allocated 0 pages
[    0.101937] cryptd: max_cpu_qlen set to 1000
[    0.104545] ACPI: Interpreter disabled.
[    0.105467] iommu: Default domain type: Translated 
[    0.105472] iommu: DMA domain TLB invalidation policy: strict mode 
[    0.105621] vgaarb: loaded
[    0.105922] SCSI subsystem initialized
[    0.106240] usbcore: registered new interface driver usbfs
[    0.106281] usbcore: registered new interface driver hub
[    0.106305] usbcore: registered new device driver usb
[    0.107091] mc: Linux media interface: v0.10
[    0.107114] videodev: Linux video capture interface: v2.00
[    0.107187] pps_core: LinuxPPS API ver. 1 registered
[    0.107190] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.107202] PTP clock support registered
[    0.107337] EDAC MC: Ver: 3.0.0
[    0.108280] FPGA manager framework
[    0.108357] Advanced Linux Sound Architecture Driver Initialized.
[    0.108867] Bluetooth: Core ver 2.22
[    0.108900] NET: Registered PF_BLUETOOTH protocol family

Welcome to NXP Real-time Ed[    0.108902] Bluetooth: HCI device and connection manager initialized
[    0.108911] Bluetooth: HCI socket layer initialized
[    0.108916] Bluetooth: L2CAP socket layer initialized
[    0.108926] Bluetooth: SCO socket layer initialized
[    0.109507] clocksource: Switched to clocksource arch_sys_counter
[    0.109652] VFS: Disk quotas dquot_6.6.0
[    0.109693] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
[    0.109860] pnp: PnP ACPI: disabled
[    0.115786] NET: Registered PF_INET protocol family
ge Distro 2.5 (kirkstone)!
[    0.115940] IP idents hash table entries: 65536 (order: 7, 524288 bytes, linear)

[    0.117094] tcp_listen_portaddr_hash hash table entries: 2048 (order: 4, 98304 bytes, linear)
[    0.117191] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.117201] TCP established hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.117469] TCP bind hash table entries: 32768 (order: 8, 1310720 bytes, linear)
[    0.118512] TCP: Hash tables configured (established 32768 bind 32768)
[    0.118641] UDP hash table entries: 2048 (order: 5, 196608 bytes, linear)
[    0.118843] UDP-Lite hash table entries: 2048 (order: 5, 196608 bytes, linear)
[    0.119159] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.119577] RPC: Registered named UNIX socket transport module.
[    0.119580] RPC: Registered udp transport module.
[    0.119582] RPC: Registered tcp transport module.
[    0.119584] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    0.120149] NET: Registered PF_XDP protocol family
[    0.120156] PCI: CLS 0 bytes, default 64
[    0.120733] hw perfevents: enabled with armv8_cortex_a53 PMU driver, 7 counters available
[    0.124142] Initialise system trusted keyrings
[    0.124273] workingset: timestamp_bits=42 max_order=20 bucket_order=0
[    0.132186] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    0.132765] NFS: Registering the id_resolver key type
[    0.132795] Key type id_resolver registered
[    0.132797] Key type id_legacy registered
[    0.132880] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[    0.132884] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[    0.132900] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
[    0.133255] 9p: Installing v9fs 9p2000 file system support
[    0.160407] Key type asymmetric registered
[    0.160413] Asymmetric key parser 'x509' registered
[    0.160471] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 243)
[    0.160475] io scheduler mq-deadline registered
[    0.160478] io scheduler kyber registered
[    0.166183] EINJ: ACPI disabled.
[    0.175710] imx-sdma 30bd0000.dma-controller: Direct firmware load for imx/sdma/sdma-imx7d.bin failed with error -2
[    0.175721] imx-sdma 30bd0000.dma-controller: Falling back to sysfs fallback for: imx/sdma/sdma-imx7d.bin
[    0.177226] mxs-dma 33000000.dma-apbh: initialized
[    0.178631] SoC: i.MX8MP revision 1.1
[    0.179127] Bus freq driver module loaded
[    0.184845] Serial: 8250/16550 driver, 4 ports, IRQ sharing enabled
[    0.186980] 30890000.serial: ttymxc1 at MMIO 0x30890000 (irq = 43, base_baud = 1500000) is a IMX
[    0.187035] printk: console [ttymxc1] enabled
[    0.199815] loop: module loaded
[    0.201141] megasas: 07.717.02.00-rc1
[    0.202601] imx ahci driver is registered.
[    0.207577] tun: Universal TUN/TAP device driver, 1.6
[    0.208216] thunder_xcv, ver 1.0
[    0.208248] thunder_bgx, ver 1.0
[    0.208287] nicpf, ver 1.0
[    0.210086] hclge is initializing
[    0.210103] hns3: Hisilicon Ethernet Network Driver for Hip08 Family - version
[    0.210106] hns3: Copyright (c) 2017 Huawei Corporation.
[    0.210151] e1000: Intel(R) PRO/1000 Network Driver
[    0.210153] e1000: Copyright (c) 1999-2006 Intel Corporation.
[    0.210189] e1000e: Intel(R) PRO/1000 Network Driver
[    0.210191] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
[    0.210232] igb: Intel(R) Gigabit Ethernet Network Driver
[    0.210234] igb: Copyright (c) 2007-2014 Intel Corporation.
[    0.210267] igbvf: Intel(R) Gigabit Virtual Function Network Driver
[    0.210269] igbvf: Copyright (c) 2009 - 2012 Intel Corporation.
[    0.210407] sky2: driver version 1.30
[    0.210902] usbcore: registered new interface driver r8152
[    0.211127] VFIO - User Level meta-driver version: 0.3
[    0.215946] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    0.215973] ehci-pci: EHCI PCI platform driver
[    0.216007] ehci-platform: EHCI generic platform driver
[    0.216151] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
[    0.216162] ohci-pci: OHCI PCI platform driver
[    0.216192] ohci-platform: OHCI generic platform driver
[    0.216795] usbcore: registered new interface driver uas
[    0.216844] usbcore: registered new interface driver usb-storage
[    0.216907] usbcore: registered new interface driver usbserial_generic
[    0.216927] usbserial: USB Serial support registered for generic
[    0.216949] usbcore: registered new interface driver ftdi_sio
[    0.216970] usbserial: USB Serial support registered for FTDI USB Serial Device
[    0.216996] usbcore: registered new interface driver usb_serial_simple
[    0.217012] usbserial: USB Serial support registered for carelink
[    0.217029] usbserial: USB Serial support registered for zio
[    0.217049] usbserial: USB Serial support registered for funsoft
[    0.217066] usbserial: USB Serial support registered for flashloader
[    0.217082] usbserial: USB Serial support registered for google
[    0.217102] usbserial: USB Serial support registered for libtransistor
[    0.217116] usbserial: USB Serial support registered for vivopay
[    0.217132] usbserial: USB Serial support registered for moto_modem
[    0.217149] usbserial: USB Serial support registered for motorola_tetra
[    0.217167] usbserial: USB Serial support registered for nokia
[    0.217183] usbserial: USB Serial support registered for novatel_gps
[    0.217199] usbserial: USB Serial support registered for hp4x
[    0.217219] usbserial: USB Serial support registered for suunto
[    0.217235] usbserial: USB Serial support registered for siemens_mpi
[    0.217267] usbcore: registered new interface driver usb_ehset_test
[    0.218927] gadgetfs: USB Gadget filesystem, version 24 Aug 2004
[    0.219758] input: 30370000.snvs:snvs-powerkey as /devices/platform/soc@0/30000000.bus/30370000.snvs/30370000.snvs:snvs-powerkey/input/input0
[    0.221773] snvs_rtc 30370000.snvs:snvs-rtc-lp: registered as rtc0
[    0.221797] snvs_rtc 30370000.snvs:snvs-rtc-lp: setting system clock to 1970-01-01T00:00:00 UTC (0)
[    0.221921] i2c_dev: i2c /dev entries driver
[    0.225907] Bluetooth: HCI UART driver ver 2.3
[    0.225916] Bluetooth: HCI UART protocol H4 registered
[    0.225919] Bluetooth: HCI UART protocol BCSP registered
[    0.225939] Bluetooth: HCI UART protocol LL registered
[    0.225941] Bluetooth: HCI UART protocol ATH3K registered
[    0.225960] Bluetooth: HCI UART protocol Three-wire (H5) registered
[    0.226044] Bluetooth: HCI UART protocol Broadcom registered
[    0.226068] Bluetooth: HCI UART protocol QCA registered
[    0.226262] EDAC MC: ECC not enabled
[    0.227649] sdhci: Secure Digital Host Controller Interface driver
[    0.227655] sdhci: Copyright(c) Pierre Ossman
[    0.228216] Synopsys Designware Multimedia Card Interface Driver
[    0.228722] sdhci-pltfm: SDHCI platform and OF driver helper
[    0.231062] SMCCC: SOC_ID: ARCH_SOC_ID not implemented, skipping ....
[    0.231185] usbcore: registered new interface driver usbhid
[    0.231188] usbhid: USB HID core driver
[    0.235582]  cs_system_cfg: CoreSight Configuration manager initialised
[  OK  ] Created slice[    0.236731] optee: probing for conduit method.
[    0.236738] optee: api uid mismatch
[    0.236739] optee: probe of firmware:optee failed with error -22
[    0.238491] Galcore version 6.4.3.p4.398061
[    0.264337] mmc2: SDHCI controller on 30b60000.mmc [30b60000.mmc] using ADMA
[    0.319513] [drm] Initialized vivante 1.0.0 20170808 for 40000000.mix_gpu_ml on minor 0
[    0.323812] pktgen: Packet Generator for packet performance testing. Version: 2.75
[    0.327425] NET: Registered PF_LLC protocol family
[    0.327454] u32 classifier
[    0.327456]     input device check on
[    0.327457]     Actions configured
[    0.327976] NET: Registered PF_INET6 protocol family
[    0.329001] Segment Routing with IPv6
[    0.329028] In-situ OAM (IOAM) with IPv6
[    0.329066] NET: Registered PF_PACKET protocol family
[    0.329177] Bluetooth: RFCOMM TTY layer initialized
[    0.329186] Bluetooth: RFCOMM socket layer initialized
[    0.329207] Bluetooth: RFCOMM ver 1.11
 Slice /system/getty[    0.329215] Bluetooth: BNEP (Ethernet Emulation) ver 1.3
[    0.329218] Bluetooth: BNEP filters: protocol multicast
[    0.329223] Bluetooth: BNEP socket layer initialized
[    0.329225] Bluetooth: HIDP (Human Interface Emulation) ver 1.2
[    0.329231] Bluetooth: HIDP socket layer initialized
[    0.329329] 8021q: 802.1Q VLAN Support v1.8
.
[    0.329346] lib80211: common routines for IEEE802.11 drivers
[    0.329419] mmc2: new HS400 Enhanced strobe MMC card at address 0001
[    0.329474] 9pnet: Installing 9P2000 support
[    0.329569] tsn generic netlink module v1 init...
[    0.329637] Key type dns_resolver registered
[    0.330192] printk: console [ttymxc1]: printing thread started
[    0.330227] mmcblk2: mmc2:0001 TY2964 58.3 GiB 
[    0.330245] Loading compiled-in X.509 certificates
[    0.336051]  mmcblk2: p1 p2 p3
[    0.359782] mmcblk2boot0: mmc2:0001 TY2964 4.00 MiB 
[    0.360988] mmcblk2boot1: mmc2:0001 TY2964 4.00 MiB 
[    0.362080] mmcblk2rpmb: mmc2:0001 TY2964 4.00 MiB, chardev (234:0)
[    0.386197] i2c 0-0022: Fixing up cyclic dependency with 38100000.usb
[    0.391067] hwmon hwmon0: temp1_input not attached to any thermal zone
[    0.391077] tmp102 0-0048: initialized
[    0.391648] RFNM: Deferring Si5510 probe...
[    0.409189] RFNM: Motherboard id 4 revision 1 serial U3D6CP3J mac-addr 00:04:9f:08:be:8e
[    0.425349] nxp-pca9450 0-0025: pca9450bc probed.
[    0.425435] i2c i2c-0: IMX I2C adapter registered
[    0.459282] RFNM: Daughterboard detected on slot 1, board id 3 revision 1 serial 24JC9ANS
[    0.460361] hwmon hwmon1: temp1_input not attached to any thermal zone
[    0.460367] tmp102 1-0048: initialized
[    0.460412] i2c i2c-1: IMX I2C adapter registered
[    0.503444] RFNM: Daughterboard detected on slot 2, board id 1 revision 1 serial YTLPXRJM
[    0.503917] tmp102 2-0048: error reading config register
[    0.504045] i2c i2c-2: IMX I2C adapter registered
[    0.504450] imx8mq-usb-phy 381f0040.usb-phy: supply vbus not found, using dummy regulator
[    0.504988] RFNM: Deferring PCIe probe...
[    0.527215] Delaying spi clock from CS by 1 clocks
[    0.528570] Delaying spi clock from CS by 0 clocks
[    0.529961] imx-dwmac 30bf0000.ethernet: IRQ eth_lpi not found
[    0.530844] imx-dwmac 30bf0000.ethernet: User ID: 0x10, Synopsys ID: 0x51
[    0.530853] imx-dwmac 30bf0000.ethernet:     DWMAC4/5
[    0.530858] imx-dwmac 30bf0000.ethernet: DMA HW capability register supported
[    0.530861] imx-dwmac 30bf0000.ethernet: RX Checksum Offload Engine supported
[    0.530864] imx-dwmac 30bf0000.ethernet: TX Checksum insertion supported
[    0.530867] imx-dwmac 30bf0000.ethernet: Wake-Up On Lan supported
[    0.530921] imx-dwmac 30bf0000.ethernet: Enable RX Mitigation via HW Watchdog Timer
[    0.530926] imx-dwmac 30bf0000.ethernet: Enabled L3L4 Flow TC (entries=8)
[    0.530931] imx-dwmac 30bf0000.ethernet: Enabled RFS Flow TC (entries=8)
[    0.530942] imx-dwmac 30bf0000.ethernet: Enabling HW TC (entries=256, max_off=256)
[    0.530947] imx-dwmac 30bf0000.ethernet: Using 34 bits DMA width
[    0.784118] dwc3 38100000.usb: Configuration mismatch. dr_mode forced to gadget
[    0.787034] imx-cpufreq-dt imx-cpufreq-dt: cpu speed grade 7 mkt segment 2 supported-hw 0x80 0x4
[    0.787922] Hot alarm is canceled. GPU3D clock will return to 64/64
[    0.791024] sdhci-esdhc-imx 30b50000.mmc: Got CD GPIO
[    0.791380] RFNM: WSLED driver
[    0.793826] remoteproc remoteproc0: imx-rproc is available
[  OK  ] Created slice[    0.812380] RFNM: Deferring Si5510 probe...
[    0.813061] imx8mq-usb-phy 382f0040.usb-phy: supply vbus not found, using dummy regulator
[    0.813977] RFNM: Deferring PCIe probe...
[    0.816608] dwhdmi-imx 32fd8000.hdmi: Detected HDMI TX controller v2.13a with HDCP (samsung_dw_hdmi_phy2)
[    0.817245] dwhdmi-imx 32fd8000.hdmi: registered DesignWare HDMI I2C bus driver
[    0.818598] imx-drm display-subsystem: bound imx-lcdifv3-crtc.0 (ops lcdifv3_crtc_ops)
[    0.818689] imx-drm display-subsystem: bound 32fd8000.hdmi (ops dw_hdmi_imx_ops)
[    0.818978] [drm] Initialized imx-drm 1.0.0 20120507 for display-subsystem on minor 1
[    0.819042] imx-drm display-subsystem: [drm] Cannot find any crtc or sizes
 Slice /system/modprobe xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
[0m.
[    0.820498] xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 1
[    0.820839] xhci-hcd xhci-hcd.1.auto: hcc params 0x0220fe6d hci version 0x110 quirks 0x0000002001010010
[    0.821013] xhci-hcd xhci-hcd.1.auto: irq 71, io mem 0x38200000
[    0.821147] xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
[    0.821156] xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 2
[    0.821167] xhci-hcd xhci-hcd.1.auto: Host supports USB 3.0 SuperSpeed
[    0.821368] mmc1: SDHCI controller on 30b50000.mmc [30b50000.mmc] using ADMA
[    0.821755] hub 1-0:1.0: USB hub found
[    0.821778] hub 1-0:1.0: 1 port detected
[    0.822088] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
[    0.822541] hub 2-0:1.0: USB hub found
[    0.822565] hub 2-0:1.0: 1 port detected
[    0.823059] RFNM: Deferring Si5510 probe...
[    0.823307] RFNM: Deferring PCIe probe...
[    0.824726] RFNM: Deferring Si5510 probe...
[    0.824932] RFNM: Deferring PCIe probe...
[    0.825772] RFNM: USB PD negotiation in progress
[    0.827195] cfg80211: Loading compiled-in X.509 certificates for regulatory database
[    0.828554] cfg80211: Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
[    0.829630] platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
[    0.829638] platform regulatory.0: Falling back to sysfs fallback for: regulatory.db
[    0.847699] ALSA device list:
[    0.847705]   No soundcards found.
[    0.909555] EXT4-fs (mmcblk2p3): recovery complete
[    0.909573] EXT4-fs (mmcblk2p3): mounted filesystem with ordered data mode. Opts: (null). Quota mode: none.
[    0.909624] VFS: Mounted root (ext4 filesystem) on device 179:3.
[    0.910564] devtmpfs: mounted
[    0.911430] Freeing unused kernel memory: 3648K
[    0.911497] Run /sbin/init as init process
[    1.011236] systemd[1]: System time before build time, advancing clock.
[    1.129619] systemd[1]: systemd 250.5+ running in system mode (+PAM -AUDIT -SELINUX -APPARMOR +IMA -SMACK +SECCOMP -GCRYPT -GNUTLS -OPENSSL +ACL +BLKID -CURL -ELFUTILS -FIDO2 -IDN2 -IDN -IPTC +KMOD -LIBCRYPTSETUP +LIBFDISK -PCRE2 -PWQUALITY -P11KIT -QRENCODE -BZIP2 -LZ4 -XZ -ZLIB +ZSTD -BPF_FRAMEWORK -XKBCOMMON +UTMP +SYSVINIT default-hierarchy=hybrid)
[    1.130140] systemd[1]: Detected architecture arm64.
[    1.263823] systemd[1]: Hostname set to <imx8mp-rfnm>.
[    1.349589] systemd-sysv-generator[226]: SysV service '/etc/init.d/netopeer2-server' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.351725] systemd-sysv-generator[226]: SysV service '/etc/init.d/save-rtc.sh' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.353117] systemd-sysv-generator[226]: SysV service '/etc/init.d/rc.local' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.356821] systemd-sysv-generator[226]: SysV service '/etc/init.d/sysrepo-init' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.357745] systemd-sysv-generator[226]: SysV service '/etc/init.d/sendsigs' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.358516] systemd-sysv-generator[226]: SysV service '/etc/init.d/umountfs' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.362332] systemd-sysv-generator[226]: SysV service '/etc/init.d/halt' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[  OK  ] Created slice[    1.362484] systemd-sysv-generator[226]: SysV service '/etc/init.d/umountnfs.sh' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.362786] systemd-sysv-generator[226]: SysV service '/etc/init.d/sysrepod' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.362918] systemd-sysv-generator[226]: SysV service '/etc/init.d/sysrepo-tsnd' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.363044] systemd-sysv-generator[226]: SysV service '/etc/init.d/reboot' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.363170] systemd-sysv-generator[226]: SysV service '/etc/init.d/single' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
 Slice /system/serial-ge[    1.363666] systemd-sysv-generator[226]: SysV service '/etc/init.d/sysrepo-plugind' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    1.697092] systemd[1]: Queued start job for default target Graphical Interface.
[    1.762848] systemd[1]: Created slice Slice /system/getty.
[    2.042069] systemd[1]: Created slice Slice /system/modprobe.
[    2.412610] systemd[1]: Created slice Slice /system/serial-getty.
tty.
[  OK  ] Created slice[    2.932481] systemd[1]: Created slice User and Session Slice.
 User and Session Slice.
[  OK  ] Started Dispatch Password …ts to [    2.954524] systemd[1]: Started Dispatch Password Requests to Console Directory Watch.
Console Directory Watch.
[  OK  ] Started Forward Password R…uests to[    2.978123] systemd[1]: Started Forward Password Requests to Wall Directory Watch.
 Wall Directory Watch.
[  OK  ] Reached target Path Units.
[    3.002414] systemd[1]: Reached target Path Units.
[  OK  ] Reached targe[    3.013277] systemd[1]: Reached target Remote File Systems.
t Remote File Systems.
[  OK  ] Reached target Slice Units.
[    3.033970] systemd[1]: Reached target Slice Units.
[  OK  ] Reached target Swaps.
[    3.046255] systemd[1]: Reached target Swaps.
[    3.069391] systemd[1]: Listening on RPCbind Server Activation Socket.
[  OK  ] Listening on RPCbind Server Activation Socket.
[    3.094591] systemd[1]: Reached target RPC Port Mapper.

[  OK  ] Listening on [    3.123220] systemd[1]: Listening on Syslog Socket.
Syslog Socket.
[  OK  ] Listening on initctl Compatibility Na[    3.142281] systemd[1]: Listening on initctl Compatibility Named Pipe.
med Pipe.
[  OK  ] Listening on [    3.166812] systemd[1]: Listening on Journal Audit Socket.
Journal Audit Socket.
[  OK  ] Listening on Journal Socket (/dev/l[    3.190658] systemd[1]: Listening on Journal Socket (/dev/log).
og).
[  OK  ] Listening on [    3.214715] systemd[1]: Listening on Journal Socket.
Journal Socket.
[  OK  ] Listening on Network Service Netlink[    3.234570] systemd[1]: Listening on Network Service Netlink Socket.
 Socket.
[  OK  ] Listening on [    3.258783] systemd[1]: Listening on udev Control Socket.
udev Control Socket.
[  OK  ] Listening on [    3.271567] systemd[1]: Listening on udev Kernel Socket.
udev Kernel Socket.
[  OK  ] Listening on [    3.284288] systemd[1]: Listening on User Database Manager Socket.
User Database Manager Socket.
         Mounting Huge Pages File System...
[    3.309606] systemd[1]: Mounting Huge Pages File System...
[    3.325782] systemd[1]: Mounting POSIX Message Queue File System...

         Mounting Kernel[    3.342881] systemd[1]: Mounting Kernel Debug File System...
 Debug File System...
[    3.362604] systemd[1]: Kernel Trace File System was skipped because of a failed condition check (ConditionPathExists=/sys/kernel/tracing).
[    3.367770] systemd[1]: tmp.mount: Directory /tmp to mount over is not empty, mounting anyway.
[    3.371962] systemd[1]: Mounting Temporary Directory /tmp...
         Mounting Temporary Directory /tmp...
         Starting Create List of Static Device Nodes.[    3.410408] systemd[1]: Starting Create List of Static Device Nodes...
..
         Starting Load Kernel Module configfs...
[    3.438126] systemd[1]: Starting Load Kernel Module configfs...
         Starting Load Kernel Module drm...
[    3.457781] systemd[1]: Starting Load Kernel Module drm...
         Starting Load Kernel Module fuse...
[    3.473746] systemd[1]: Starting Load Kernel Module fuse...
[    3.488780] fuse: init (API version 7.34)
[    3.490841] systemd[1]: Starting RPC Bind...
         Starting RPC Bind...
[    3.509941] systemd[1]: File System Check on Root Device was skipped because of a failed condition check (ConditionPathIsReadWrite=!/).
[    3.510619] systemd[1]: systemd-journald.service: unit configures an IP firewall, but the local system does not support BPF/cgroup firewalling.
[    3.510633] systemd[1]: (This warning is only shown for the first unit using IP firewalling.)
[    3.515858] systemd[1]: Starting Journal Service...
         Starting Journal Service...
[    3.567603] systemd[1]: Load Kernel Modules was skipped because all trigger condition checks failed.
[    3.571636] systemd[1]: Starting Generate network units from Kernel command line...
         Starting Generate network …ts from Kernel command line...
         Starting Remount Root and Kernel File Systems systemd[1]: Starting Remount Root and Kernel File Systems...
[0m...
[    3.623870] EXT4-fs (mmcblk2p3): re-mounted. Opts: (null). Quota mode: none.
         Starting Apply Kernel Variables...
[    3.646430] systemd[1]: Starting Apply Kernel Variables...
         Starting Coldplug All udev Devices...
[    3.662109] systemd[1]: Starting Coldplug All udev Devices...
[  OK  ] Started     3.681011] systemd[1]: Started RPC Bind.
;39mRPC Bind.
[  OK  ] Started Journal Service.
[    3.698511] systemd[1]: Started Journal Service.
[  OK  ] Mounted Huge Pages File System.
[  OK  ] Mounted POSIX Message Queue File System.
[  OK  ] Mounted Kernel Debug File System.
[  OK  ] Mounted Temporary Directory /tmp.
[  OK  ] Finished Create List of Static Device Nodes.
[  OK  ] Finished Load Kernel Module configfs.
[  OK  ] Finished Load Kernel Module drm.
[  OK  ] Finished Load Kernel Module fuse.
[  OK  ] Finished Generate network units from Kernel command line.
[  OK  ] Finished Remount Root and Kernel File Systems.
[  OK  ] Finished Apply Kernel Variables.
         Mounting FUSE Control File System...
         Mounting Kernel Configuration File System...
         Starting Flush Journal to Persistent Storage...
[    3.982391] systemd-journald[236]: Received client request to flush runtime journal.
         Starting Create Static Device Nodes in /dev...
[  OK  ] Mounted FUSE Control File System.
[  OK  ] Mounted Kernel Configuration File System.
[  OK  ] Finished Flush Journal to Persistent Storage.
[  OK  ] Finished Create Static Device Nodes in /dev.
[  OK  ] Reached target Preparation for Local File Systems.
         Mounting /var/volatile...
         Starting Rule-based Manage…for Device Events and Files...
[  OK  ] Mounted /var/volatile.
         Starting Load/Save Random Seed...
[  OK  ] Reached target Local File Systems.
         Starting Create Volatile Files and Directories...
[  OK  ] Started Rule-based Manager for Device Events and Files.
[  OK  ] Finished Coldplug All udev Devices.
[  OK  ] Finished Create Volatile Files and Directories.
         Starting Network Time Synchronization...
         Starting Record System Boot/Shutdown in UTMP...
[  OK  ] Finished Record System Boot/Shutdown in UTMP.
[    4.602071] caam 30900000.crypto: device ID = 0x0a16040100000100 (Era 9)
[    4.602082] caam 30900000.crypto: job rings = 2, qi = 0
[    4.608044] RFNM: Starting up Si5510...
[    4.631466] caam-snvs 30370000.caam-snvs: violation handlers armed - non-secure state
[    4.658808] Error: Driver 'typec_fusb302' is already registered, aborting...
[    4.744898] imx-hdmi sound-hdmi: failed to find SAI platform device
[    4.744911] imx-hdmi: probe of sound-hdmi failed with error -22
[    4.754070] systemd-journald[236]: Oldest entry in /run/log/journal/1fc882a4576a4a98aaaf873e0d2602e0/system.journal is older than the configured file retention duration (1month), suggesting rotation.
[    4.754086] systemd-journald[236]: /run/log/journal/1fc882a4576a4a98aaaf873e0d2602e0/system.journal: Journal header limits reached or header out-of-date, rotating.
[  OK  ] Started Network Time Synchronization.
[  OK  ] Reached target System Initialization.
[  OK  ] Started Daily Cleanup of Temporary Directories.
[  OK  ] Reached target System Time Set.
[  OK  ] Started Daily rotation of log files.
[  OK  ] Reached target Timer Units.
[    4.874631] audit: type=1701 audit(1770178517.823:2): auid=4294967295 uid=0 gid=0 ses=4294967295 pid=307 comm="vsidaemon" exe="/usr/bin/vsidaemon" sig=6 res=1
[  OK  ] Listening on Avahi mDNS/DNS-SD Stack Activation Socket.
[  OK  ] Listening on D-Bus System Message Bus Socket.
         Starting Docker Socket for the API...
[  OK  ] Listening on dropbear.socket.
         Starting Weston socket...
[  OK  ] Listening on Docker Socket for the API.
[  OK  ] Listening on Weston socket.
[  OK  ] Reached target Socket Units.
[  OK  ] Reached target Basic System.
[  OK  ] Reached target Hardware activated USB gadget.
[  OK  ] Started Job spooling tools.
[  OK  ] Started Avahi DNS Configuration Daemon.
[    5.188816] random: crng init done
[  OK  ] Started Periodic Command Scheduler.
         Starting D-Bus System Message Bus...
         Starting Ethernet Bridge Filtering Tables...
[  OK  ] Started Linux Firmware Loader Daemon.
[  OK  ] Started Configuration for i.MX GPU [    5.305654] imx-sdma 30e10000.dma-controller: firmware found.
[    5.305910] imx-sdma 30bd0000.dma-controller: firmware found.
(Former rc_gpu.S).
[    5.306079] imx-sdma 30bd0000.dma-controller: loaded firmware 4.6
         Starting IPv6 Packet Filtering Framework...
         Starting IPv4 Packet Filtering Framework...
[    5.381948] caam algorithms registered in /proc/crypto
[    5.382815] caam 30900000.crypto: caam pkc algorithms registered in /proc/crypto
         Starting Networ[    5.382935] caam 30900000.crypto: rng crypto API alg registered prng-caam
k Time Service (one-shot ntpdate [    5.382946] caam 30900000.crypto: registering rng-caam
mode)...
[    5.384746] Device caam-keygen registered
         Starting Telephony service...
[  OK  ] Started System Logging Service.
         Starting sysrepo-init.service...
         Starting User Login Management...
[  OK  ] Started TEE Supplicant.
[  OK  ] Started D-Bus System Message Bus.
[  OK  ] Finished Load/Save Random Seed.
[  OK  ] Finished Ethernet Bridge Filtering Tables.
[  OK  ] Finished IPv6 Packet Filtering Framework.
[  OK  ] Finished IPv4 Packet Filtering Framework.
[  OK  ] Finished Network Time Service (one-shot ntpdate mode).
[  OK  ] Started sysrepo-init.service.
[  OK  ] Started Telephony service.
[  OK  ] Started User Login Management.
[  OK  ] Created slice Slice /system/systemd-fsck.
[  OK  ] Reached target Preparation for Network.
         Starting sysrepod.service...
         Starting File System Check on /dev/mmcblk2p2...
         Starting Network Configuration...
[  OK  ] Finished File System Check on /dev/mmcblk2p2.
[  OK  ] Started sysrepod.service.
         Mounting /run/media/boot-mmcblk2p2...
         Starting sysrepo-plugind.service...
[  OK  ] Started sysrepo-plugind.service.
[  OK  ] Mounted /run/media/boot-mmcblk2p2.
         Starting sysrepo-tsnd.service...
[  OK  ] Started sysrepo-tsnd.service.
[  OK  ] Started Network Configuration.
         Starting netopeer2-server.service...
         Starting Network Name Resolution...
[  OK  ] Started netopeer2-server.service.
[  OK  ] Started Network Name Resolution.
[  OK  ] Reached target Network.
[  OK  ] Reached target Host and Network Name Lookups.
         Starting Avahi mDNS/DNS-SD Stack...
         Starting containerd container runtime...
         Starting LLDP daemon...
[  OK  ] Started NFS status monitor for NFSv2/3 locking..
[  OK  ] Started Respond to IPv6 Node Information Queries.
         Starting /etc/rc.local Compatibility...
[    6.844324] xhci-hcd xhci-hcd.1.auto: remove, state 4
[    6.844343] usb usb2: USB disconnect, device number 1
[  OK  ] Started     6.845299] xhci-hcd xhci-hcd.1.auto: USB bus 2 deregistered
;39mNetwork Router Discovery Daem[    6.845319] xhci-hcd xhci-hcd.1.auto: remove, state 4
[    6.845328] usb usb1: USB disconnect, device number 1
on.
[    6.846697] xhci-hcd xhci-hcd.1.auto: USB bus 1 deregistered
[    6.880699] audit: type=1701 audit(1770178519.827:11): auid=4294967295 uid=0 gid=0 ses=4294967295 pid=626 comm="sysrepod" exe="/usr/bin/sysrepod" sig=11 res=1
         Starting Permit User Sessions...
[  OK  ] Started /etc/rc.local Compatibility.
[  OK  ] Finished Permit User Sessions.
[    6.969877] audit: type=1701 audit(1770178519.919:12): auid=4294967295 uid=0 gid=0 ses=4294967295 pid=643 comm="sysrepod" exe="/usr/bin/sysrepod" sig=11 res=1
[  OK  ] Started Avahi mDNS/DNS-SD Stack.
[  OK  ] Started Getty on tty1.
[  OK  ] Started Serial Getty on ttymxc1.
[  OK  ] Reached target Login Prompts.
         Starting Weston, a Wayland…ositor, as a system service...
[  OK  ] Started LLDP daemon.
         Starting User Database Manager...
[    7.213923] la9310shiva: loading out-of-tree module taints kernel.
[    7.215529] NXP PCIe LA9310 Driver.
[    7.221740] LA9310 IPC driver: major_nr 509, minor 0
[    7.221955] NXP-LA9310-Driver 0000:01:00.0: max payload size    rc:128 ep:256
[    7.221977] NXP-LA9310-Driver 0000:01:00.0: Init -  !
[    7.221981] NXP-LA9310-Driver 0000:01:00.0: BAR:0  addr:0x18000000 len:0x4000000
[    7.221986] NXP-LA9310-Driver 0000:01:00.0: BAR:1  addr:0x1c000000 len:0x20000
[    7.221990] NXP-LA9310-Driver 0000:01:00.0: BAR:2  addr:0x1f000000 len:0x800000
[    7.222569] NXP-LA9310-Driver 0000:01:00.0: mem[0] phy 18000000, vaddr ffff800024000000
[    7.222589] NXP-LA9310-Driver 0000:01:00.0: mem[1] phy 1c000000, vaddr ffff80000afc0000
[    7.222690] NXP-LA9310-Driver 0000:01:00.0: mem[2] phy 1f000000, vaddr ffff800028800000
[    7.222697] la9310_dev_set_interrupt_capability
[    7.222699] PCI_INT_MODE_MULTIPLE_MSI
[    7.223073] NXP-LA9310-Driver 0000:01:00.0: 8 MSI successfully created
[    7.223665] NXP-LA9310-Driver 0000:01:00.0: Virtual address after ioremap=ffff80002c000000
[    7.301862] NXP-LA9310-Driver 0000:01:00.0: Scratch buf DMA ATU done
[    7.301874] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[4] offset 0
[    7.301878] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002c000000, EP Phys a0000000, size 2097152
[    7.301884] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002c200000, size 64
[    7.301888] NXP-LA9310-Driver 0000:01:00.0: New offset - 2097216
[    7.301892] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[5] offset 2097216
[    7.301896] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002c200040, EP Phys a0200040, size 0
[    7.301901] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002c200040, size 64
[    7.301904] NXP-LA9310-Driver 0000:01:00.0: New offset - 2097280
[    7.301908] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[6] offset 2097280
[    7.301912] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002c200080, EP Phys a0200080, size 98304
[    7.301916] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002c218080, size 64
[    7.301920] NXP-LA9310-Driver 0000:01:00.0: New offset - 2195648
[    7.301924] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[7] offset 2195648
[    7.301927] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002c2180c0, EP Phys a02180c0, size 4096
[    7.301932] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002c2190c0, size 64
[    7.301936] NXP-LA9310-Driver 0000:01:00.0: New offset - 2199808
[    7.301939] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[8] offset 2199808
[    7.301943] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002c219100, EP Phys a0219100, size 20971520
[    7.301948] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002d619100, size 64
[    7.301952] NXP-LA9310-Driver 0000:01:00.0: New offset - 23171392
[    7.301955] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[9] offset 23171392
[    7.301959] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002d619140, EP Phys a1619140, size 16777216
[    7.301963] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002e619140, size 64
[    7.301967] NXP-LA9310-Driver 0000:01:00.0: New offset - 39948672
[    7.301971] NXP-LA9310-Driver 0000:01:00.0: subdrv DMA region:[10] offset 39948672
[    7.301974] NXP-LA9310-Driver 0000:01:00.0: Host virtual ffff80002e619180, EP Phys a2619180, size 131072
[    7.301979] NXP-LA9310-Driver 0000:01:00.0: Paint addr ffff80002e639180, size 64
[    7.301983] NXP-LA9310-Driver 0000:01:00.0: New offset - 40079808
[    7.301988] NXP-LA9310-Driver 0000:01:00.0: RFNM IQFLOOD Buff:0xc0000000[H]-0x96400000[M],size 218103808
[    7.301994] NXP-LA9310-Driver 0000:01:00.0: RFNM OCRAM Buff:0xd0000000[H]-0x900000[M],size 524288
[  OK  ] Started     7.302098] NXP-LA9310-Driver 0000:01:00.0: LA9310 Logger init vaddr ffff80002c2180c0, phys a02180c0, size 4096
;39mUser Database Manager.
[    7.302137] NXP-LA9310-Driver 0000:01:00.0: Created sysfs group la9310sysfs
[    7.302143] NXP-LA9310-Driver 0000:01:00.0: nlm0: Loading RTOS image
[    7.303133] NXP-LA9310-Driver 0000:01:00.0: Downloaded f/w at 0xffff80000ae0d000 size: 64276
[    7.303146] NXP-LA9310-Driver 0000:01:00.0: Copy fw to ffff80002c200080, size 64276
[    7.303237] NXP-LA9310-Driver 0000:01:00.0: ### dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
[    7.303242] NXP-LA9310-Driver 0000:01:00.0: udev Firmware [la9310.bin] - Addr ffff80002c200080, size 64276
[    7.303264] NXP-LA9310-Driver 0000:01:00.0: Waiting for FreeRTOS boot.
[    7.405602] NXP-LA9310-Driver 0000:01:00.0: [Sync fw upgrade] Waiting for FreeRTOS to write 1
[    7.598021] phy phy-382f0040.usb-phy.1: VBUS is coming from a dedicated power supply.
[    7.613715] NXP-LA9310-Driver 0000:01:00.0: LA9310 FreeRTOS booted succesfully: 0x1
[    7.613731] NXP-LA9310-Driver 0000:01:00.0:  la9310_dev->hif->irq_evt_regs 0x00000601
[    7.613736] NXP-LA9310-Driver 0000:01:00.0:  &la9310_dev->hif->irq_evt_regs 0xffff80000afdc014
[    7.613740] NXP-LA9310-Driver 0000:01:00.0: num_irq 6
[    7.613744] NXP-LA9310-Driver 0000:01:00.0: CCSR: vaddr ffff800024000000, size 67108864
[    7.613751] NXP-LA9310-Driver 0000:01:00.0: MSI:ATU: DBI 0xffff800027400054, DMA 44032000, EP b0000000
[    7.613757] NXP-LA9310-Driver 0000:01:00.0: MSI ATU done
[    7.618567] NXP-LA9310-Driver 0000:01:00.0: irq mux 238 allocated successfully
[    7.618572] NXP-LA9310-Driver 0000:01:00.0: &ScratchRegisterHandshake 0xffff800001382200
[    7.623780] NXP-LA9310-Driver 0000:01:00.0: nlm0: Initiating Reset handshake
[    7.623793] NXP-LA9310-Driver 0000:01:00.0: [Reset HS] Waiting for FreeRTOS to write 3
[    7.671481] NXP-LA9310-Driver 0000:01:00.0: Host Handshake interrupt boom!! irq num 241
[    7.671519] NXP-LA9310-Driver 0000:01:00.0: LA9310 Reset HSHAKE done, scratch 0x3
[    7.677236] NXP-LA9310-Driver 0000:01:00.0: HIF Version : 1.0
[    7.677254] NXP-LA9310-Driver 0000:01:00.0: nlm0:Initiating sub-drivers
[    7.677261] NXP-LA9310-Driver 0000:01:00.0: subdrv [IPC] virqmap init
[  OK  ] Created slice[    7.677297] NXP-LA9310-Driver 0000:01:00.0: virqmap init, evtmask f, count 4
 User Slice of UID 0[    7.677301] NXP-LA9310-Driver 0000:01:00.0: Inside la9310_ipc_probe function K_hif=2a0
.
[    7.777571] NXP-LA9310-Driver 0000:01:00.0: IPC modem is ready!
[    7.777587] NXP-LA9310-Driver 0000:01:00.0: Exiting function la9310_ipc_probe
[    7.777596] NXP-LA9310-Driver 0000:01:00.0: subdrv [VSPA] virqmap init
[    7.777636] NXP-LA9310-Driver 0000:01:00.0: virqmap init, evtmask 10, count 1
[    7.779092] NXP-LA9310-Driver 0000:01:00.0: nlm0-vspa0: hwver 0x02011500, 16 AUs, dmem 6400 bytes
         Starting User R[    7.779107] NXP-LA9310-Driver 0000:01:00.0: INFO:vspa_probe : VSPA Loading firmware initiated-
[    7.779170] NXP-LA9310-Driver 0000:01:00.0: ### vspa_dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
untime Directory /run/user/0...
[  OK  ] Started containerd container runtime.
[  OK  ] Finished User Runtime Directory /run/user/0.
[  OK  ] Reached target Multi-User System.
         Starting User Manager for UID 0...
[    7.985636] NXP-LA9310-Driver 0000:01:00.0: ### vspa_dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
[    8.193685] NXP-LA9310-Driver 0000:01:00.0: ### vspa_dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
[    8.218436] phy phy-382f0040.usb-phy.1: VBUS is coming from a dedicated power supply.
[  OK  ] Started User Manager for UID 0.
[  OK  ] Started Session c1 of User root.
[    8.408400] NXP-LA9310-Driver 0000:01:00.0: Downloaded f/w at 0xffff80001c1b5000 size: 668892
[    8.408416] NXP-LA9310-Driver 0000:01:00.0: Copy fw to ffff80002c000000, size 668892
[    8.411878] NXP-LA9310-Driver 0000:01:00.0: ### vspa_dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
[    8.621767] NXP-LA9310-Driver 0000:01:00.0: ### vspa_dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
[  OK  ] Started Weston, a Wayland …mpositor, as a system service.
[  OK  ] Reached target Graphical Interface.
[    8.829703] NXP-LA9310-Driver 0000:01:00.0: Section Name: .IQ_data_ovl_ddr found
         Starting Record[    8.829720] NXP-LA9310-Driver 0000:01:00.0: Section Name: .CAL_ovl_ddr found
 Runlevel Change in UTMP...
[    8.829778] NXP-LA9310-Driver 0000:01:00.0: ### vspa_dma_region->vaddr ffff80002c200080 dma_addr 000080006c200080
[  OK  ] Finished Record Runlevel Change in UTMP.
[    9.038309] NXP-LA9310-Driver 0000:01:00.0: INFO:vspa_probe :VSPA FW image apm.eld loading finished
[    9.038318] NXP-LA9310-Driver 0000:01:00.0: Boot Ok Msg Verified: msb = F1000000, lsb = 00000000
[    9.038325] NXP-LA9310-Driver 0000:01:00.0: SW Version: vspa = 00020002, ippu = 00000000
[    9.038333] NXP-LA9310-Driver 0000:01:00.0: SPM Ack Msg: msb = F0700000, lsb = 00000000
[    9.047310] [kpg_nc] MAIR = 0x40044FFFF
[    9.047319] [kpg_nc] ATTR-0 = 0xFF
[    9.047321] [kpg_nc] ATTR-1 = 0xFF
[    9.047323] [kpg_nc] ATTR-2 = 0x44
[    9.047325] [kpg_nc] ATTR-3 = 0x00
[    9.047327] [kpg_nc] ATTR-4 = 0x04
[    9.047329] [kpg_nc] ATTR-5 = 0x00
[    9.047331] [kpg_nc] ATTR-6 = 0x00
[    9.047333] [kpg_nc] ATTR-7 = 0x00
[    9.047335] [kpg_nc] NC attribute found at 2
[    9.047337] [kpg_nc] Successfully loaded.
[    9.058314] NXP-LA9310-Driver 0000:01:00.0: Mapped rfnm_bufdesc_rx from 96400000 to ffff000056400000 size 18874368
[    9.058330] NXP-LA9310-Driver 0000:01:00.0: Mapped rfnm_bufdesc_tx from 97600000 to ffff000057600000 size 34603008
[    9.058336] NXP-LA9310-Driver 0000:01:00.0: Mapped rfnm_rx_usb_buf from 9b600000 to ffff00005b600000 size 12587008
[    9.058349] NXP-LA9310-Driver 0000:01:00.0: RFNM Callback registered
[    9.058513] rc returned 0
[    9.058597] rc returned 0
[    9.072534] init rfnm_daughterboard
[    9.083772] Mass Storage Function, version: 2009/09/11
[    9.083781] LUN: removable file: (no medium)
[    9.083817] using random self ethernet address
[    9.083821] using random host ethernet address
[    9.083950] LUN: file: /rfnm/scripts/backing_storage
[    9.083954] Number of LUNs=1
[    9.084025] Sending os driver data from callback
[    9.084028] allocating table from function file
[    9.087903] usb0: HOST MAC f2:60:af:19:8c:63
[    9.087917] usb0: MAC be:68:e8:4e:48:d7
[    9.087970] callback ok
[    9.087978] rfnm_usb gadget: rfnm_usb ready
[    9.095946] Sending os driver data from callback
[    9.095957] allocating table from function file
[    9.095968] callback ok
[    9.095974] rfnm_usb_boost gadget: rfnm_usb_boost ready
[    9.106467] SPI driver rfnm_lime has no spi_device_id for rfnm,daughterboard
[    9.106603] RFNM: Loading Lime driver for daughterboard at slot 0
[    9.107007] ver 0x7, rev 0x1, mask 0x1
[    9.205781] RFNM: Lime daughterboard initialized
[    9.219258] SPI driver rfnm_granita has no spi_device_id for rfnm,daughterboard
[    9.225331] SPI driver rfnm_breakout has no spi_device_id for rfnm,daughterboard
[    9.225458] RFNM: Loading Breakout (dummy) driver for daughterboard at slot 1
[    9.226990] remoteproc remoteproc0: powering up imx-rproc
[    9.229852] remoteproc remoteproc0: Booting fw image rfnm_m7_v0.elf, size 270548
[    9.381597] sourcesink_set_alt
[    9.381611] in ep qlen 16 size 98336
[    9.382555] out ep qlen 8 size 98336
[    9.383037] in ep qlen 16 size 98336
[    9.383966] out ep qlen 8 size 98336
[    9.384437] in ep qlen 16 size 98336
[    9.385363] out ep qlen 8 size 98336
[    9.385890] in ep qlen 16 size 98336
[    9.386825] out ep qlen 8 size 98336
[    9.758390] remoteproc remoteproc0: remote processor imx-rproc is now up
[    9.885539] imx-dwmac 30bf0000.ethernet eth0: Link is Up - 1Gbps/Full - flow control rx/tx
[    9.885581] IPv6: ADDRCONF(NETDEV_CHANGE): eth0: link becomes ready

NXP Real-time Edge Distro 2.5 imx8mp-rfnm ttymxc1

imx8mp-rfnm login: [   15.072612] kauditd_printk_skb: 29 callbacks suppressed
[   15.072623] audit: type=1701 audit(1770178528.019:38): auid=4294967295 uid=0 gid=0 ses=4294967295 pid=858 comm="vsidaemon" exe="/usr/bin/vsidaemon" sig=6 res=1

imx8mp-rfnm login: [   67.495266] stopping OUT process
[   67.495381] stopping IN process
[   67.496043] Stopping USB process
[   67.496754] ------------[ cut here ]------------
[   67.496757] Voluntary context switch within RCU read-side critical section!
[   67.496767] WARNING: CPU: 0 PID: 844 at kernel/rcu/tree_plugin.h:316 rcu_note_context_switch+0x328/0x3e4
[   67.496785] Modules linked in: rfnm_breakout(O) rfnm_granita(O) rfnm_lime(O) rfnm_usb_boost(O) rfnm_usb(O) rfnm_usb_function(O) rfnm_daughterboard(O) rfnm_lalib(O) la9310rfnm(O) rfnm_gpio(O) kpage_ncache(O) la9310shiva(O) overlay fsl_jr_uio caam_jr caamkeyblob_desc caamhash_desc caamalg_desc crypto_engine authenc libdes crct10dif_ce dw_hdmi_cec snd_soc_fsl_xcvr snd_soc_imx_hdmi secvio caam error fuse
[   67.496839] CPU: 0 PID: 844 Comm: irq/70-s-dwc3 Tainted: G           O      5.15.71-rt51 #27
[   67.496845] Hardware name: RFNM imx8mp (DT)
[   67.496847] pstate: 600000c5 (nZCv daIF -PAN -UAO -TCO -DIT -SSBS BTYPE=--)
[   67.496852] pc : rcu_note_context_switch+0x328/0x3e4
[   67.496857] lr : rcu_note_context_switch+0x328/0x3e4
[   67.496864] sp : ffff80001bbfb540
[   67.496866] x29: ffff80001bbfb540 x28: ffff0000c0feb400 x27: ffff0000c5aaeb00
[   67.496875] x26: ffff0000c18b5280 x25: ffff0000c4cae3c0 x24: ffff800009fd1000
[   67.496883] x23: 0000000000000000 x22: ffff0000c4cae3c0 x21: ffff0000c4cae3c0
[   67.496891] x20: ffff800009b0e900 x19: ffff0000ff780900 x18: fffffffffffef3d0
[   67.496899] x17: 000000040044ffff x16: 00400032b5503510 x15: 0000000000000048
[   67.496910] x14: 0000225268f4c230 x13: 216e6f6974636573 x12: 206c616369746972
[   67.496918] x11: 6320656469732d64 x10: 6165722055435220 x9 : 206e696874697720
[   67.496927] x8 : ffff800009df29e8 x7 : ffff80001bbfb390 x6 : 000000000000000c
[   67.496935] x5 : ffff0000ff778bc8 x4 : 0000000000000000 x3 : 0000000000000027
[   67.496945] x2 : 0000000000000000 x1 : 0000000000000000 x0 : ffff0000c4cae3c0
[   67.496953] Call trace:
[   67.496955]  rcu_note_context_switch+0x328/0x3e4
[   67.496960]  __schedule+0xc4/0x690
[   67.496965]  schedule+0xb4/0x14c
[   67.496971]  schedule_timeout+0xc0/0xf0
[   67.496978]  wait_for_completion_killable+0x84/0x160
[   67.496983]  __kthread_create_on_node+0xbc/0x180
[   67.496992]  kthread_create_on_node+0x54/0x80
[   67.496997]  kthread_create_on_cpu+0x34/0x90
[   67.497004]  start_sm+0x28/0x90 [la9310rfnm]
[   67.497015]  rfnm_restart_sm+0x1c/0x90 [la9310rfnm]
[   67.497023]  sourcesink_setup+0x118/0x4f0 [rfnm_usb_function]
[   67.497034]  composite_setup+0x604/0x196c
[   67.497041]  dwc3_ep0_interrupt+0x3f8/0x7c0
[   67.497049]  dwc3_thread_interrupt+0x784/0xacc
[   67.497053]  irq_thread_fn+0x2c/0xa0
[   67.497063]  irq_thread+0x1bc/0x294
[   67.497072]  kthread+0x188/0x1a0
[   67.497077]  ret_from_fork+0x10/0x20
[   67.497084] ---[ end trace 0000000000000002 ]---
[   68.512572] sched: RT throttling activated
[   71.080593] stopping IN process
[   71.080922] stopping OUT process
[   71.081348] Stopping USB process
[   71.105764] 0 - Actual RX LO freq 2450000000 Hz
[   71.110950] rx ch 0 code 0 freq 2450000000
[   71.110964] rx ch 0 code 0 freq 2450000000
[   71.110968] rx ch 1 code 0 freq 2450000000
[   71.110970] stream -> 0 tx 0 rx 0 0 0 0
[   71.127321] 0 - Actual RX LO freq 2450000000 Hz
[   71.132958] rx ch 0 code 0 freq 2450000000
[   71.133026] stream -> 0 tx 0 rx 0 0 0 0
[   71.149387] 0 - Actual RX LO freq 2450000000 Hz
[   71.154783] rx ch 0 code 0 freq 2450000000
[   71.154844] stream -> 0 tx 0 rx 0 0 0 0
[   71.170806] 0 - Actual RX LO freq 2450000000 Hz
[   71.175892] rx ch 0 code 0 freq 2450000000
[   71.175962] stream -> 0 tx 0 rx 0 0 0 0
[   71.195092] 0 - Actual RX LO freq 1850000000 Hz
[   71.199966] rx ch 0 code 0 freq 1850000000
[   71.199980] stream -> 0 tx 0 rx 0 0 0 0
[   71.218795] 0 - Actual RX LO freq 1850000000 Hz
[   71.223855] rx ch 0 code 0 freq 1850000000
[   71.223924] stream -> 0 tx 0 rx 0 0 0 0
[   71.317380] 0 - Actual RX LO freq 1850000000 Hz
[   71.321968] rx ch 0 code 0 freq 1850000000
[   71.321983] stream -> 8 tx 0 rx 2 0 0 0
[   73.039054] 0 - Actual RX LO freq 1850000000 Hz
[   73.043570] rx ch 0 code 0 freq 1850000000
[   73.043585] stream -> 0 tx 0 rx 0 0 0 0