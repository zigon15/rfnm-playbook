#---- Configuration ----#
BUILD_DIR     := ../../../build
OUTPUT_DIR    := $(BUILD_DIR)/rfnm-debian-rootfs
ROOT_PASSWORD := rfnm
HOSTNAME      := rfnm
ARCH          := arm64
DISTRO        := bookworm
MIRROR        := http://deb.debian.org/debian
QEMU_STATIC   := /usr/bin/qemu-aarch64-static

# Marker file to track if build is done
STAMP_FILE    := $(OUTPUT_DIR)/.build_complete

#---- Targets ----#
.PHONY: all build clean help

all: build

# The 'build' target depends on the stamp file.
# If the stamp file exists, Make says "Nothing to be done".
build: 
	@echo "--- [1/4] Creating Directory ---"
	mkdir -p $(OUTPUT_DIR)

	@echo "--- [2/4] Running Debootstrap Stage 1 (Download) ---"
	sudo debootstrap --arch=$(ARCH) --foreign $(DISTRO) $(OUTPUT_DIR) $(MIRROR)

	@echo "--- [3/4] Copying QEMU Static Binary ---"
	sudo cp $(QEMU_STATIC) $(OUTPUT_DIR)/usr/bin/

	@echo "--- [4/4] Running Stage 2 (Configuration) ---"
	# We use 'bash -c' to run multiple commands inside the chroot safely
	sudo chroot $(OUTPUT_DIR) /bin/bash -c "\
		/debootstrap/debootstrap --second-stage && \
		echo 'root:$(ROOT_PASSWORD)' | chpasswd && \
		echo '$(HOSTNAME)' > /etc/hostname"
	
	@echo "--- Build Complete! ---"

clean:
	@echo "--- Cleaning Build Directory ---"
	# sudo is required because debootstrap creates files owned by root
	sudo rm -rf $(OUTPUT_DIR)
	@echo "Clean complete."

help:
	@echo "Available targets:"
	@echo "  make build   - Create the Debian rootfs (only runs if needed)"
	@echo "  make clean   - Delete the rootfs (requires sudo)"