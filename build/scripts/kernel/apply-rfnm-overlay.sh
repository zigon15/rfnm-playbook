#!/bin/sh
set -e

# Apply RFNM overlay on top of upstream NXP linux-imx kernel tree.
# Called from checkoutGoodCommits.sh after cloning the upstream kernel.

KDIR=/work/build/imx8mp-kernel
OVERLAY=/work/scripts/kernel/rfnm-overlay

echo "[apply-rfnm-overlay] Copying RFNM-specific files into kernel tree..."
cp -r "$OVERLAY/." "$KDIR/"

# --- Insert RFNM Kconfig / Makefile entries into upstream files ---

# Device Tree Makefile — append unconditionally; duplication is harmless
DT_MF="$KDIR/arch/arm64/boot/dts/freescale/Makefile"
if ! grep -q 'imx8mp-rfnm.dtb' "$DT_MF"; then
    echo "[apply-rfnm-overlay] Adding RFNM device trees to DT Makefile..."
    echo 'dtb-$(CONFIG_ARCH_MXC) += imx8mp-rfnm.dtb' >> "$DT_MF"
    echo 'dtb-$(CONFIG_ARCH_MXC) += imx8mp-rfnm-rescue.dtb' >> "$DT_MF"
fi

# I2C busses Makefile — append just before the final ccflags line, if present.
I2C_MF="$KDIR/drivers/i2c/busses/Makefile"
if ! grep -q 'CONFIG_RFNM_SI5510' "$I2C_MF"; then
    echo "[apply-rfnm-overlay] Adding RFNM I2C Makefile entries..."
    awk '/^ccflags-\$\(CONFIG_I2C_DEBUG_BUS\)/ {
        print "obj-$(CONFIG_RFNM_SI5510)	+= i2c-rfnm-si5510.o"
        print "obj-$(CONFIG_RFNM_BOOTCONFIG)	+= i2c-rfnm-bootconfig.o"
    }
    {print}' "$I2C_MF" > "${I2C_MF}.tmp" && mv "${I2C_MF}.tmp" "$I2C_MF"
fi

# I2C busses Kconfig — append to end of file (outside any menu, which is valid)
I2C_KC="$KDIR/drivers/i2c/busses/Kconfig"
if ! grep -q 'config RFNM_SI5510' "$I2C_KC"; then
    echo "[apply-rfnm-overlay] Adding RFNM I2C Kconfig entries..."
    cat >> "$I2C_KC" <<'EOF'

config RFNM_SI5510
	tristate "Enable RFNM's Si5510 boot init"
	help
	  Fast init to get pcie running at boot

config RFNM_BOOTCONFIG
	tristate "Enable RFNM's EEPROM bootconfig driver"
	help
	  Read EEPROM from mother/daughterboards at boot and populate board configs
EOF
fi

# LEDs Kconfig — append to end of file
LED_KC="$KDIR/drivers/leds/Kconfig"
if ! grep -q 'config LEDS_RFNM_WSLED' "$LED_KC"; then
    echo "[apply-rfnm-overlay] Adding RFNM LED Kconfig entry..."
    cat >> "$LED_KC" <<'EOF'

config LEDS_RFNM_WSLED
	tristate "Enable RFNM's WS2812B driver"
	depends on LEDS_CLASS
	help
	  This simple driver bitbangs LEDs connected to GPIOs, so it
	  depends on CPU frequency, which is assumed as 1600 MHz.
EOF
fi

# LEDs Makefile — insert after the LEDS_TRIGGERS line if present
LED_MF="$KDIR/drivers/leds/Makefile"
if ! grep -q 'CONFIG_LEDS_RFNM_WSLED' "$LED_MF"; then
    echo "[apply-rfnm-overlay] Adding RFNM LED Makefile entry..."
    awk '/^obj-\$\(CONFIG_LEDS_TRIGGERS\)/ {
        print
        print "obj-$(CONFIG_LEDS_RFNM_WSLED)\t\t\t+= leds-rfnm-wsled.o"
        next
    }
    {print}' "$LED_MF" > "${LED_MF}.tmp" && mv "${LED_MF}.tmp" "$LED_MF"
fi

# Verify the overlay actually took
for f in arch/arm64/configs/imx8mp_rfnm_defconfig include/linux/rfnm-api.h include/linux/rfnm-shared.h drivers/i2c/busses/i2c-rfnm-si5510.c drivers/leds/leds-rfnm-wsled.c; do
    if [ ! -f "$KDIR/$f" ]; then
        echo "[apply-rfnm-overlay] ERROR: expected overlay file not found: $f" >&2
        exit 1
    fi
done

echo "[apply-rfnm-overlay] Done."
