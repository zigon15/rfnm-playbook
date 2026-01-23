# Building Bootable SD Card

## Build Container
If only building code
- `./buildContainer.sh`

If flashing sd card, copy container to root
- `./copyContainerRoot.sh`

## Run Container
To just build the required code
- `./buildContainer.sh`

To build the required code and create a bootable sd card
1. `./copyContainerRoot.sh`
1. `sudo ./runContainer.sh /dev/sdb`

## Build Linux with Debian RootFS
In container CLI
- `./buildLinux.sh`