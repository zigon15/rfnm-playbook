# Build

The easiest way to build is with podman. Manual way is missing the repo patches to stop the builds failing.

## Podman Build
1. `./buildContainer.sh`
1. `./copyContainerRoot.sh` We need to run container as root to be able to flash SD card
1. `sudo ./runContainer.sh /dev/sdX` where sdX is the sd card you want to flash
1. `./buildLinux.sh`
1. `./flashSD.sh`

Ensure the RFNM boot switches are set to SD. Insert SD card and it should boot. Currently only the serial terminal and SSH works. Desktop in progress.