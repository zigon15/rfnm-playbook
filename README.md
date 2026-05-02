# RFNM Playbook

Build system for creating bootable Debian-based Linux images for RFNM devices (NXP iMX8MP).

Builds: ARM Trusted Firmware, U-Boot, Linux Kernel 6.1+, Debian 12 (ARM64), LA9310 driver, librfnm.

See **[build/README.md](build/README.md)** for full build and flash instructions.

## Quick Start

```bash
cd build

# Build the container (one-time)
./buildContainer.sh

# Run container, mapping in your SD card
sudo ./runContainer.sh /dev/sdX

# Inside the container — build everything, then flash
python3 /work/scripts/build.py
/work/scripts/flashSD.sh
```

## After Flashing

1. Insert SD card into the RFNM board
2. Set boot switches to SD card mode — see [docs/device.md](docs/device.md)
3. Connect serial console: **UART2 TX/RX pins**, 115200 baud, 8N1
4. Power on — default logins: `root` / `rfnm`, or `rfnm` / `rfnm`
5. Find on network: `sudo arp-scan --localnet | grep -iE "nxp|freescale"`
