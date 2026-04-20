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
    ('selected',     'fg:#00ff00'),
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


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print(f'\n{BOLD}{CYAN}╔══════════════════════════════════════════╗{NC}')
    print(f'{BOLD}{CYAN}║    RFNM Linux Build Configuration        ║{NC}')
    print(f'{BOLD}{CYAN}╚══════════════════════════════════════════╝{NC}\n')

    # ── Question 1: rootfs variant ─────────────────────────────────────────────
    rootfs_choice = questionary.select(
        'Rootfs variant:',
        choices=[
            questionary.Choice('Weston   — Wayland compositor + Vivante GL', value='weston'),
            questionary.Choice('Desktop  — KDE Plasma desktop',               value='desktop'),
            questionary.Choice('Base     — Headless, no display',             value='base'),
        ],
        default='weston',
        style=STYLE,
    ).ask()

    if rootfs_choice is None:
        sys.exit(1)  # Ctrl-C

    # ── Question 2: LA9310 support ─────────────────────────────────────────────
    build_rfnm = questionary.confirm(
        'Include RFNM LA9310 support (RTOS firmware, kernel driver, librfnm)?',
        default=True,
        style=STYLE,
    ).ask()

    if build_rfnm is None:
        sys.exit(1)  # Ctrl-C

    # ── Derived values ─────────────────────────────────────────────────────────
    ROOTFS_SCRIPTS = {
        'weston':  'buildWeston_GalcoreGPU.sh',
        'desktop': 'buildDesktop_GalcoreGPU.sh',
        'base':    'build_GalcoreGPU.sh',
    }
    rootfs_script = ROOTFS_SCRIPTS[rootfs_choice]
    rootfs_name   = rootfs_choice.capitalize()

    # ── Build plan summary ─────────────────────────────────────────────────────
    DIM = '\033[2m'
    print(f'\n{BOLD}Build plan:{NC}')
    print(f'  {GREEN}✓{NC}  Repositories  (clone + firmware)')
    print(f'  {GREEN}✓{NC}  U-Boot + ARM Trusted Firmware')
    print(f'  {GREEN}✓{NC}  Linux Kernel')
    if build_rfnm:
        print(f'  {GREEN}✓{NC}  LA9310 RTOS Firmware')
        print(f'  {GREEN}✓{NC}  LA9310 Kernel Driver')
    else:
        print(f'  {DIM}✗  LA9310  (skipped){NC}')
    print(f'  {GREEN}✓{NC}  Debian Rootfs  ({rootfs_name})')
    if build_rfnm:
        print(f'  {GREEN}✓{NC}  RFNM Overlay  (scripts + unit tests)')
    else:
        print(f'  {DIM}✗  RFNM Overlay  (skipped){NC}')
    print(f'  {GREEN}✓{NC}  Kernel Modules')
    if build_rfnm:
        print(f'  {GREEN}✓{NC}  RFNM Libraries  (librfnm + installRfnm)')
    else:
        print(f'  {DIM}✗  RFNM Libraries  (skipped){NC}')

    confirmed = questionary.confirm(
        '\nStart building?',
        default=True,
        style=STYLE,
    ).ask()

    if not confirmed:
        print('Aborted.')
        sys.exit(0)

    # ── Build steps ────────────────────────────────────────────────────────────

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

    run_step('Building U-Boot + ARM Trusted Firmware', '''
        set -e
        cd /work/scripts/uboot
        ./buildATF.sh
        ./build.sh
    ''')

    run_step('Building Linux Kernel', '''
        set -e
        cd /work/scripts/kernel
        ./build_GalcoreGPU.sh
    ''')

    if build_rfnm:
        run_step('Building LA9310 RTOS Firmware', '''
            set -e
            cd /work/scripts/la9310-rtos
            ./build.sh
        ''')

        run_step('Building LA9310 Kernel Driver', '''
            set -e
            cd /work/scripts/la9310-driver
            ./build.sh
        ''')

    run_step(f'Building Debian Rootfs  ({rootfs_name})', f'''
        set -e
        cd /work/scripts/debian
        ./{rootfs_script}
    ''')

    if build_rfnm:
        run_step('Installing RFNM Overlay', '''
            set -e
            OVERLAY=/work/scripts/debian/rootfs-overlay/rfnm
            BUILD_DIR=/work/build/debian
            if [ -d "$OVERLAY" ]; then
                cp -rv "$OVERLAY/"* "$BUILD_DIR/"
            fi
        ''')

    run_step('Installing Kernel Modules', '''
        set -e
        cd /work/scripts/debian
        ./installKernelModules.sh
    ''')

    if build_rfnm:
        run_step('Installing RFNM Libraries', '''
            set -e
            cd /work/scripts/debian
            ./installRfnm.sh
        ''')

    # ── Done ───────────────────────────────────────────────────────────────────
    echo_step('Build complete!')
    print(f'\n{GREEN}{BOLD}✓  All steps completed successfully.{NC}\n', flush=True)


if __name__ == '__main__':
    main()
