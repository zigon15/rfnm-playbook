#!/usr/bin/env python3
"""
RFNM Linux Build Orchestrator
Presents an interactive configuration menu then runs all build steps.
Replaces buildLinux.sh — run this directly inside the container.
"""

import os
import sys
import subprocess
import questionary
from questionary import Style

# ── ANSI colours ──────────────────────────────────────────────────────────────
CYAN  = '\033[0;36m'
GREEN = '\033[0;32m'
RED   = '\033[0;31m'
BOLD  = '\033[1m'
NC    = '\033[0m'

# ── questionary style ─────────────────────────────────────────────────────────
STYLE = Style([
    ('qmark',        'fg:#00ffff bold'),
    ('question',     'bold'),
    ('answer',       'fg:#00ff00 bold'),
    ('pointer',      'fg:#00ffff bold'),
    ('highlighted',  'fg:#00ffff bold'),
    ('selected',     'fg:#5f87ff'),
    ('separator',    'fg:#444444'),
    ('instruction',  'fg:#888888'),
])

# ── Helpers ───────────────────────────────────────────────────────────────────

def echo_step(label):
    print(f'\n{CYAN}{"─" * 60}{NC}', flush=True)
    print(f'{CYAN}  {label}{NC}', flush=True)
    print(f'{CYAN}{"─" * 60}{NC}', flush=True)


def run_step(label, cmd):
    echo_step(label)
    result = subprocess.run(cmd, shell=True, executable='/bin/bash')
    if result.returncode != 0:
        print(f'\n{RED}✗  FAILED: {label}  (exit {result.returncode}){NC}', flush=True)
        sys.exit(result.returncode)


# ── Shared: ask flash target + devices ───────────────────────────────────────

def list_block_devices():
    """Return list of (device, description) for all top-level block devices."""
    try:
        out = subprocess.check_output(
            ['lsblk', '-d', '-e', '7,11,259', '-o', 'NAME,SIZE,MODEL,TRAN', '--noheadings'],
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    devices = []
    for line in out.splitlines():
        parts = line.split()
        if not parts:
            continue
        name = '/dev/' + parts[0]
        rest = ' '.join(parts[1:])  # SIZE MODEL TRAN
        devices.append((name, f'{name}  {rest}'))
    return devices


def ask_device(prompt, env_var):
    """Select a block device from a list, with a manual-entry fallback."""
    default = os.environ.get(env_var, '')
    devices = list_block_devices()

    MANUAL = '__manual__'
    if devices:
        choices = [questionary.Choice(desc, value=dev) for dev, desc in devices]
        choices.append(questionary.Choice('Enter manually…', value=MANUAL))
        preselect = default if any(dev == default for dev, _ in devices) else devices[0][0]
        answer = questionary.select(
            prompt,
            choices=choices,
            default=preselect,
            style=STYLE,
        ).ask()
        if answer is None:
            sys.exit(1)
        if answer != MANUAL:
            return answer

    # Manual entry (fallback or user chose it)
    answer = questionary.text(prompt, default=default, style=STYLE).ask()
    if not answer:
        sys.exit(1)
    return answer


def ask_flash():
    flash_choice = questionary.select(
        'After building:',
        choices=[
            questionary.Choice('Just build — no flashing',                             value='none'),
            questionary.Choice('Flash SD   — everything on SD card',                   value='sd'),
            questionary.Choice('Flash SD + USB — U-Boot on SD, kernel+rootfs on USB',  value='sd_usb'),
        ],
        style=STYLE,
    ).ask()
    if flash_choice is None:
        sys.exit(1)

    sd_device  = None
    usb_device = None

    if flash_choice in ('sd', 'sd_usb'):
        sd_device = ask_device('SD card device:', 'FLASH_DEVICE')

    if flash_choice == 'sd_usb':
        usb_device = ask_device('USB drive device:', 'USB_DEVICE')

    return flash_choice, sd_device, usb_device


# ── Shared: execute build + flash steps ───────────────────────────────────────

def execute(steps, rootfs_script, rootfs_name, flash_choice, sd_device, usb_device):
    DIM = '\033[2m'

    # Build plan summary
    print(f'\n{BOLD}Build plan:{NC}')
    install_la9310 = steps.get('la9310_rtos') or steps.get('la9310_driver')

    labels = [
        ('repos',          'Repositories  (clone + firmware)'),
        ('uboot',          'U-Boot + ARM Trusted Firmware'),
        ('kernel',         'Linux Kernel'),
        ('la9310_rtos',    'LA9310 RTOS Firmware'),
        ('la9310_driver',  'LA9310 Kernel Driver'),
        ('rootfs',         f'Debian Rootfs  ({rootfs_name})'),
        ('kernel_modules', 'Kernel Modules'),
    ]
    if install_la9310:
        labels.append(('_la9310_install', 'LA9310 overlay + driver/firmware install  (auto)'))
    for key, label in labels:
        active = steps.get(key) if not key.startswith('_') else install_la9310
        if active:
            print(f'  {GREEN}✓{NC}  {label}')
        else:
            print(f'  {DIM}✗  {label}  (skipped){NC}')

    if flash_choice == 'sd':
        print(f'  {GREEN}✓{NC}  Flash SD card  ({sd_device})')
    elif flash_choice == 'sd_usb':
        print(f'  {GREEN}✓{NC}  Flash U-Boot → SD  ({sd_device})')
        print(f'  {GREEN}✓{NC}  Flash kernel+rootfs → USB  ({usb_device})')
    else:
        print(f'  {DIM}✗  Flash  (skipped){NC}')

    confirmed = questionary.confirm('\nStart?', default=True, style=STYLE).ask()
    if not confirmed:
        print('Aborted.')
        sys.exit(0)

    # Build steps
    if steps.get('repos'):
        run_step('Getting repositories', '''
            set -e
            cd /work/scripts/git
            ./cloneRepos.sh
            ./checkoutGoodCommits.sh
            ./getFirmware.sh
        ''')
        if not os.path.isdir('/work/build/firmware/firmware-imx-8.16/'):
            print(f'\n{RED}✗  FAIL: Firmware not found: /work/build/firmware/firmware-imx-8.16/{NC}', flush=True)
            sys.exit(1)

    if steps.get('uboot'):
        run_step('Building U-Boot + ARM Trusted Firmware', '''
            set -e
            cd /work/scripts/uboot
            ./clean.sh
            ./buildATF.sh
            ./build.sh
        ''')

    if steps.get('kernel'):
        run_step('Building Linux Kernel', '''
            set -e
            cd /work/scripts/kernel
            ./clean.sh
            ./build_GalcoreGPU.sh
        ''')

    if steps.get('la9310_rtos'):
        run_step('Building LA9310 RTOS Firmware', '''
            set -e
            cd /work/scripts/la9310-rtos
            ./clean.sh
            ./build.sh
        ''')

    if steps.get('la9310_driver'):
        run_step('Building LA9310 Kernel Driver', '''
            set -e
            cd /work/scripts/la9310-driver
            ./clean.sh
            ./build.sh
        ''')

    if steps.get('rootfs'):
        run_step(f'Building Debian Rootfs  ({rootfs_name})', f'''
            set -e
            cd /work/scripts/debian
            ./clean.sh
            ./{rootfs_script}
        ''')

    if steps.get('kernel_modules'):
        run_step('Installing Kernel Modules', '''
            set -e
            cd /work/scripts/debian
            ./sub/installKernelModules.sh
        ''')

    if install_la9310:
        run_step('Installing LA9310 overlay + driver/firmware', '''
            set -e
            OVERLAY=/work/scripts/debian/rootfs-overlay/rfnm
            BUILD_DIR=/work/build/debian
            if [ -d "$OVERLAY" ]; then
                cp -rv "$OVERLAY/"* "$BUILD_DIR/"
            fi
            cd /work/scripts/debian
            ./sub/installRfnm.sh
        ''')

    # Flash steps
    if flash_choice == 'sd':
        run_step(f'Flashing everything to SD card  ({sd_device})', f'''
            set -e
            FLASH_DEVICE={sd_device} /work/scripts/flashSD.sh
        ''')
    elif flash_choice == 'sd_usb':
        run_step(f'Flashing U-Boot to SD card  ({sd_device})', f'''
            set -e
            FLASH_DEVICE={sd_device} /work/scripts/flashSD_UBootUsb.sh
        ''')
        run_step(f'Flashing kernel + rootfs to USB  ({usb_device})', f'''
            set -e
            USB_DEVICE={usb_device} /work/scripts/flashUSB_Linux.sh
        ''')

    echo_step('All done!')
    print(f'\n{GREEN}{BOLD}✓  All steps completed successfully.{NC}\n', flush=True)


# ── Main ──────────────────────────────────────────────────────────────────────

ROOTFS_SCRIPTS = {
    'weston':  'buildWeston_GalcoreGPU.sh',
    'desktop': 'buildDesktop_GalcoreGPU.sh',
    'base':    'build_GalcoreGPU.sh',
}


def main():
    print(f'\n{BOLD}{CYAN}╔══════════════════════════════════════════╗{NC}')
    print(f'{BOLD}{CYAN}║    RFNM Linux Build Configuration        ║{NC}')
    print(f'{BOLD}{CYAN}╚══════════════════════════════════════════╝{NC}\n')

    # ── Top-level action ───────────────────────────────────────────────────────
    action = questionary.select(
        'What do you want to do?',
        choices=[
            questionary.Choice('Build             — compile only',                   value='build'),
            questionary.Choice('Build and flash   — compile then flash',             value='build_flash'),
            questionary.Choice('Flash             — flash pre-built artifacts now',  value='flash'),
        ],
        style=STYLE,
    ).ask()
    if action is None:
        sys.exit(1)

    # ── Flash only ─────────────────────────────────────────────────────────────
    if action == 'flash':
        flash_choice = questionary.select(
            'Flash target:',
            choices=[
                questionary.Choice('Flash SD   — everything on SD card',                   value='sd'),
                questionary.Choice('Flash SD + USB — U-Boot on SD, kernel+rootfs on USB',  value='sd_usb'),
            ],
            style=STYLE,
        ).ask()
        if flash_choice is None:
            sys.exit(1)
        sd_device = ask_device('SD card device:', 'FLASH_DEVICE')
        usb_device = ask_device('USB drive device:', 'USB_DEVICE') if flash_choice == 'sd_usb' else None
        steps = {k: False for k in ('repos', 'uboot', 'kernel', 'la9310_rtos',
                                     'la9310_driver', 'rootfs', 'kernel_modules')}
        execute(steps, 'build_GalcoreGPU.sh', 'Base', flash_choice, sd_device, usb_device)
        return

    # ── Build mode ─────────────────────────────────────────────────────────────
    mode = questionary.select(
        'Build mode:',
        choices=[
            questionary.Choice('Full build — clone repos and build everything', value='full'),
            questionary.Choice('Partial    — rebuild selected components only', value='partial'),
        ],
        style=STYLE,
    ).ask()
    if mode is None:
        sys.exit(1)

    # ── Full build ─────────────────────────────────────────────────────────────
    if mode == 'full':
        rootfs_choice = questionary.select(
            'Rootfs variant:',
            choices=[
                questionary.Choice('Weston   — Wayland compositor + Vivante GL', value='weston'),
                questionary.Choice('Desktop  — KDE Plasma desktop  (broken)',     value='desktop'),
                questionary.Choice('Base     — Headless',                         value='base'),
            ],
            style=STYLE,
        ).ask()
        if rootfs_choice is None:
            sys.exit(1)

        build_rfnm = questionary.confirm(
            'Include RFNM LA9310 support (RTOS firmware, kernel driver, librfnm)?',
            default=True,
            style=STYLE,
        ).ask()
        if build_rfnm is None:
            sys.exit(1)

        if action == 'build_flash':
            flash_choice, sd_device, usb_device = ask_flash()
        else:
            flash_choice, sd_device, usb_device = 'none', None, None

        steps = {
            'repos':          True,
            'uboot':          True,
            'kernel':         True,
            'la9310_rtos':    build_rfnm,
            'la9310_driver':  build_rfnm,
            'rootfs':         True,
            'kernel_modules': True,
        }
        rootfs_script = ROOTFS_SCRIPTS[rootfs_choice]
        rootfs_name   = rootfs_choice.capitalize()

    # ── Partial rebuild ────────────────────────────────────────────────────────
    else:
        selected = questionary.checkbox(
            'Select components to rebuild:',
            choices=[
                questionary.Choice('U-Boot + ATF',         value='uboot'),
                questionary.Choice('Linux Kernel',         value='kernel'),
                questionary.Choice('LA9310 RTOS Firmware', value='la9310_rtos'),
                questionary.Choice('LA9310 Kernel Driver', value='la9310_driver'),
                questionary.Choice('Debian Rootfs',        value='rootfs'),
                questionary.Choice('Kernel Modules',       value='kernel_modules'),
            ],
            style=STYLE,
        ).ask()
        if selected is None:
            sys.exit(1)
        if not selected:
            print('Nothing selected — exiting.')
            sys.exit(0)

        # Only ask rootfs variant if rootfs is being rebuilt
        rootfs_choice = 'weston'  # default, unused if rootfs not selected
        if 'rootfs' in selected:
            rootfs_choice = questionary.select(
                'Rootfs variant:',
                choices=[
                    questionary.Choice('Weston   — Wayland compositor + Vivante GL', value='weston'),
                    questionary.Choice('Desktop  — KDE Plasma desktop  (broken)',     value='desktop'),
                    questionary.Choice('Base     — Headless',                         value='base'),
                ],
                style=STYLE,
            ).ask()
            if rootfs_choice is None:
                sys.exit(1)

        if action == 'build_flash':
            flash_choice, sd_device, usb_device = ask_flash()
        else:
            flash_choice, sd_device, usb_device = 'none', None, None

        steps = {k: k in selected for k in
                 ('uboot', 'kernel', 'la9310_rtos', 'la9310_driver',
                  'rootfs', 'kernel_modules')}
        steps['repos'] = False
        rootfs_script = ROOTFS_SCRIPTS[rootfs_choice]
        rootfs_name   = rootfs_choice.capitalize()

    execute(steps, rootfs_script, rootfs_name, flash_choice, sd_device, usb_device)


if __name__ == '__main__':
    main()
