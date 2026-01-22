# Build Debian RootFS

## Prerequisites
Install debian rootfs app
- ```sudo apt install debootstrap```

Get qemu-user-static
1. ```wget https://github.com/multiarch/qemu-user-static/releases/latest/download/qemu-aarch64-static```
1. ```chmod +x qemu-aarch64-static```
1. ```sudo mv qemu-aarch64-static /usr/bin/```


## Create RootFS

Create folder
- ```mkdir rfnm-debian-rootfs```

Bootstrap a basic Debian Bookworm (stable) system for ARM64
- ```sudo debootstrap --arch=arm64 --foreign bookworm ./rfnm-debian-rootfs http://deb.debian.org/debian```

Copy qemu-aarch64-static to the rootfs (allows running arm64 binaries on x64)
- ```sudo cp /usr/bin/qemu-aarch64-static ./rfnm-debian-rootfs/usr/bin/```

Enter the rootfs to finish configuration
- ```sudo chroot ./rfnm-debian-rootfs /bin/bash```

(Inside the chroot)
- ```/debootstrap/debootstrap --second-stage```

Set a password for root
- ```passwd```

Exit chroot
- ```exit```

Install kerneel models, assuming you are back in your kernel source folder
- ```make INSTALL_MOD_PATH=/path/to/rfnm-debian-rootfs modules_install```