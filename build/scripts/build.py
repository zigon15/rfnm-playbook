#!/usr/bin/env python3
"""
RFNM Linux Build Orchestrator
Presents an interactive configuration menu then runs all build steps.
Replaces buildLinux.sh — run this directly inside the container.
"""

import os
import sys
import subprocess
import time
from dataclasses import dataclass, field
from typing import Optional
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
    ('selected',     'noinherit'),
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


# ── Rootfs stage selection ────────────────────────────────────────────────────

# Stage labels for variants that support staged builds. Variants not listed
# here fall back to a simple fresh/skip-clean choice.
ROOTFS_STAGE_LABELS = {
    'weston': [
        (1, 'debootstrap base system'),
        (2, 'configure (packages, users, networking)'),
        (4, 'download Vivante GPU + Hantro VPU'),
        (5, 'compile weston-imx'),
        (6, 'merge + overlays (assemble final rootfs)'),
        (7, 'install kernel modules + NXP firmware'),
    ],
}


def ask_rootfs_build_mode(rootfs_choice):
    """Ask how to build the rootfs. Returns (fresh: bool, stages: list[int]|None).

    stages=None means run all stages (default). A list means run only those
    numbered stages; the shell script receives them as STAGES="1 2 3 …".
    """
    stage_defs = ROOTFS_STAGE_LABELS.get(rootfs_choice)

    if stage_defs is None:
        # Variant doesn't yet support staged builds.
        mode = questionary.select(
            'Rootfs build mode:',
            choices=[
                questionary.Choice('Build from scratch  (wipes build dirs first)', value='fresh'),
                questionary.Choice('Skip clean  (reuse existing build dir)',        value='skip'),
            ],
            style=STYLE,
        ).ask()
        if mode is None:
            sys.exit(1)
        return (mode == 'fresh'), None

    mode = questionary.select(
        'Rootfs build mode:',
        choices=[
            questionary.Choice('Build from scratch  (wipes build dirs first)', value='fresh'),
            questionary.Choice('Select stages to run',                          value='select'),
        ],
        style=STYLE,
    ).ask()
    if mode is None:
        sys.exit(1)
    if mode == 'fresh':
        return True, None

    # Stages 6 (merge) and 7 (kernel-modules) always run — hide from checkbox.
    checkbox_stages = [(n, lbl) for n, lbl in stage_defs if n not in (6, 7)]
    choices = [
        questionary.Choice(f'{n} — {label}', value=n, checked=True)
        for n, label in checkbox_stages
    ]
    selected = questionary.checkbox(
        'Stages to run:',
        choices=choices,
        style=STYLE,
    ).ask()
    if selected is None:
        sys.exit(1)

    # Stages 6 (merge) and 7 (kernel-modules) always run after the selected
    # build stages. Return the full list explicitly (never None) so the RFNM
    # policy in the caller can decide whether to add stage 8.
    selected = sorted(set(selected) | {6, 7})
    return False, selected


def ask_include_rfnm_support(default=True):
    include = questionary.confirm(
        'Include RFNM support in rootfs (overlay + LA9310 artifacts)?',
        default=default,
        style=STYLE,
    ).ask()
    if include is None:
        sys.exit(1)
    return include


def ask_rfnm_load_on_startup(default=True):
    return questionary.confirm(
        'Load RFNM drivers on startup?',
        default=default,
        style=STYLE,
    ).ask()


def ask_usb_a_mode():
    return questionary.select(
        'USB-A port mode:',
        choices=[
            questionary.Choice('Device (USB boost)', value='device'),
            questionary.Choice('Host (keyboard/mouse)', value='host'),
        ],
        default='device',
        style=STYLE,
    ).ask()


def ask_rfnm_options(default_include=True):
    """Ask all RFNM-related questions. Returns (include, load_on_startup, usb_a_mode)."""
    include = ask_include_rfnm_support(default=default_include)
    if include:
        return include, ask_rfnm_load_on_startup(), ask_usb_a_mode()
    return include, False, 'device'


# ── Build configuration ───────────────────────────────────────────────────────

@dataclass
class BuildConfig:
    steps: dict = field(default_factory=lambda: {
        k: False for k in ('repos', 'uboot', 'kernel', 'dtbs',
                           'la9310_rtos', 'la9310_driver', 'rootfs')
    })
    rootfs_choice: str = 'weston'
    rootfs_script: str = 'build_GalcoreGPU.sh'
    rootfs_name: str = 'Base'
    rootfs_fresh: bool = False
    rootfs_stages: Optional[list] = None
    include_rfnm_rootfs: bool = False
    rfnm_load_on_startup: bool = False
    usb_a_mode: str = 'device'
    flash_choice: str = 'none'
    sd_device: Optional[str] = None
    usb_device: Optional[str] = None


# ── Build summary ─────────────────────────────────────────────────────────────

def status_icon(ok):
    return '✅' if ok else '❌'


def print_build_summary(title, cfg, elapsed_seconds=None):
    rootfs_selected = cfg.steps.get('rootfs', False)

    # Build stage state list for weston variant
    stage_states = []
    if rootfs_selected and cfg.rootfs_choice == 'weston':
        stage_defs = ROOTFS_STAGE_LABELS['weston']
        run_set = {n for n, _ in stage_defs} if cfg.rootfs_stages is None else set(cfg.rootfs_stages)
        stage_states = [(n, label, n in run_set) for n, label in stage_defs]

    # Rootfs mode label
    if cfg.rootfs_stages is not None:
        mode_label = f'Selected stages ({", ".join(str(s) for s in cfg.rootfs_stages)})'
    elif cfg.rootfs_fresh:
        mode_label = 'Build from scratch'
    else:
        mode_label = 'All stages (reuse existing build dir)'

    print(f'\n----- {title} -----')
    print(f'{status_icon(cfg.steps.get("repos", False))} Repos cloned')
    print(f'{status_icon(cfg.steps.get("uboot", False))} U-Boot + ATF rebuilt')
    kernel_icon = status_icon(cfg.steps.get('kernel', False) or cfg.steps.get('dtbs', False))
    print(f'{kernel_icon} Kernel')
    print(f'   {status_icon(cfg.steps.get("kernel", False))} Kernel rebuilt')
    print(f'   {status_icon(cfg.steps.get("dtbs", False))} Device Trees rebuilt')
    print(f'{status_icon(cfg.steps.get("la9310_rtos", False))} LA9310 RTOS rebuilt')
    print(f'{status_icon(cfg.steps.get("la9310_driver", False))} LA9310 Driver rebuilt')

    if rootfs_selected:
        print(f'{status_icon(True)} Rootfs rebuilt ({cfg.rootfs_name})')
        print(f'   Mode: {mode_label}')
        for num, label, ran in stage_states:
            print(f'   {status_icon(ran)} Stage {num} — {label}')
        if cfg.include_rfnm_rootfs:
            print(f'   {status_icon(True)} Stage 8 — install RFNM LA9310 driver + firmware')
            print(f'      USB-A mode: {cfg.usb_a_mode}')
            print(f'      Load on startup: {"yes" if cfg.rfnm_load_on_startup else "no"}')
    else:
        print(f'{status_icon(False)} Rootfs rebuilt ({cfg.rootfs_name}) (skipped)')

    if cfg.flash_choice == 'sd':
        print(f'✅ Flash SD ({cfg.sd_device})')
    elif cfg.flash_choice == 'sd_usb':
        print(f'✅ Flash SD ({cfg.sd_device}) + USB ({cfg.usb_device})')
    else:
        print('❌ Flash (skipped)')
    if elapsed_seconds is not None:
        minutes, seconds = divmod(int(elapsed_seconds), 60)
        hours, minutes = divmod(minutes, 60)
        print(f'Time taken: {hours:02d}:{minutes:02d}:{seconds:02d}')
    print('-------------------------')


# ── Shared: execute build + flash steps ───────────────────────────────────────

def execute(cfg):
    start_time = time.time()
    print_build_summary('Build Plan', cfg)

    confirmed = questionary.confirm('\nStart?', default=True, style=STYLE).ask()
    if not confirmed:
        print('Aborted.')
        sys.exit(0)

    # Build steps
    if cfg.steps.get('repos'):
        run_step('Cleaning build directory', '''
            cd /work/scripts
            ./clean.sh
        ''')
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

    if cfg.steps.get('uboot'):
        run_step('Building U-Boot + ARM Trusted Firmware', '''
            set -e
            cd /work/scripts/uboot
            ./clean.sh
            ./buildATF.sh
            ./build.sh
        ''')

    if cfg.steps.get('kernel'):
        run_step('Building Linux Kernel', '''
            set -e
            cd /work/scripts/kernel
            ./clean.sh
            ./build_GalcoreGPU.sh
        ''')

    if cfg.steps.get('dtbs'):
        run_step('Building Device Trees', '''
            set -e
            cd /work/scripts/kernel
            ./build_DTBs.sh
        ''')

    if cfg.steps.get('la9310_rtos'):
        run_step('Building LA9310 RTOS Firmware', '''
            set -e
            cd /work/scripts/la9310-rtos
            ./clean.sh
            ./build.sh
        ''')

    if cfg.steps.get('la9310_driver'):
        run_step('Building LA9310 Kernel Driver', '''
            set -e
            cd /work/scripts/la9310-driver
            ./clean.sh
            ./build.sh
        ''')

    if cfg.steps.get('rootfs'):
        cmd_parts = ['set -e', 'cd /work/scripts/debian']
        if cfg.rootfs_fresh:
            cmd_parts.append('./clean.sh')
        rfnm_support = '1' if cfg.include_rfnm_rootfs else '0'
        rfnm_load = '1' if cfg.rfnm_load_on_startup else '0'
        if cfg.rootfs_stages is not None:
            stages_str = ' '.join(str(s) for s in cfg.rootfs_stages)
            cmd_parts.append(f'RFNM_SUPPORT="{rfnm_support}" RFNM_LOAD_ON_STARTUP="{rfnm_load}" USB_A_MODE="{cfg.usb_a_mode}" STAGES="{stages_str}" ./{cfg.rootfs_script}')
        else:
            cmd_parts.append(f'RFNM_SUPPORT="{rfnm_support}" RFNM_LOAD_ON_STARTUP="{rfnm_load}" USB_A_MODE="{cfg.usb_a_mode}" ./{cfg.rootfs_script}')
        run_step(f'Building Debian Rootfs  ({cfg.rootfs_name})', '\n'.join(cmd_parts))

    # Flash steps
    if cfg.flash_choice == 'sd':
        run_step(f'Flashing everything to SD card  ({cfg.sd_device})', f'''
            set -e
            FLASH_DEVICE={cfg.sd_device} /work/scripts/flashSD.sh
        ''')
    elif cfg.flash_choice == 'sd_usb':
        run_step(f'Flashing U-Boot to SD card  ({cfg.sd_device})', f'''
            set -e
            FLASH_DEVICE={cfg.sd_device} /work/scripts/flashSD_UBootUsb.sh
        ''')
        run_step(f'Flashing kernel + rootfs to USB  ({cfg.usb_device})', f'''
            set -e
            USB_DEVICE={cfg.usb_device} /work/scripts/flashUSB_Linux.sh
        ''')

    print_build_summary(
        'Build Summary', cfg,
        elapsed_seconds=time.time() - start_time
    )
    echo_step('All done!')
    print(f'\n{GREEN}{BOLD}✓  All steps completed successfully.{NC}\n', flush=True)


# ── Main ──────────────────────────────────────────────────────────────────────

ROOTFS_SCRIPTS = {
    'weston':  'buildWeston_GalcoreGPU.sh',
    'desktop': 'buildDesktop_GalcoreGPU.sh',
    'base':    'build_GalcoreGPU.sh',
}

ROOTFS_NAMES = {
    'weston':  'Weston  (Wayland compositor + Vivante GL)',
    'desktop': 'Desktop',
    'base':    'Base',
}

ROOTFS_VARIANT_CHOICES = [
    questionary.Choice('Weston   — Wayland compositor + Vivante GL', value='weston'),
    questionary.Choice('Desktop  — KDE Plasma desktop  (broken)',    value='desktop'),
    questionary.Choice('Base     — Headless',                        value='base'),
]


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
        cfg = BuildConfig(
            steps={k: False for k in ('repos', 'uboot', 'kernel', 'dtbs', 'la9310_rtos',
                                       'la9310_driver', 'rootfs')},
            rootfs_choice='base',
            flash_choice=flash_choice,
            sd_device=sd_device,
            usb_device=usb_device,
        )
        execute(cfg)
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
            choices=ROOTFS_VARIANT_CHOICES,
            style=STYLE,
        ).ask()
        if rootfs_choice is None:
            sys.exit(1)

        include_rfnm, rfnm_load, usb_a = ask_rfnm_options(default_include=True)

        cfg = BuildConfig(
            steps={
                'repos':         True,
                'uboot':         True,
                'kernel':        True,
                'la9310_rtos':   include_rfnm,
                'la9310_driver': include_rfnm,
                'rootfs':        True,
            },
            rootfs_choice=rootfs_choice,
            rootfs_fresh=True,
            rootfs_stages=None,
            include_rfnm_rootfs=include_rfnm,
            rfnm_load_on_startup=rfnm_load,
            usb_a_mode=usb_a,
        )

    # ── Partial rebuild ────────────────────────────────────────────────────────
    else:
        selected = questionary.checkbox(
            'Select components to rebuild:',
            choices=[
                questionary.Choice('Prepare repos (clone + firmware + apply patches)', value='repos'),
                questionary.Choice('U-Boot + ATF',         value='uboot'),
                questionary.Choice('Linux Kernel',         value='kernel'),
                questionary.Choice('LA9310 RTOS Firmware', value='la9310_rtos'),
                questionary.Choice('LA9310 Kernel Driver', value='la9310_driver'),
                questionary.Choice('Debian Rootfs',        value='rootfs'),
            ],
            style=STYLE,
        ).ask()
        if selected is None:
            sys.exit(1)
        if not selected:
            print('Nothing selected — exiting.')
            sys.exit(0)

        kernel_mode = 'full'
        if 'kernel' in selected:
            kernel_mode = questionary.select(
                'Kernel build mode:',
                choices=[
                    questionary.Choice('Full build   — clean + build Image, DTBs + modules', value='full'),
                    questionary.Choice('Device Tree  — build DTBs only (fast)',              value='dtbs'),
                ],
                default='full',
                style=STYLE,
            ).ask()
            if kernel_mode is None:
                sys.exit(1)
            if kernel_mode == 'dtbs':
                selected.remove('kernel')
                selected.append('dtbs')

        needs_deploy = any(c in selected for c in ('kernel', 'dtbs', 'la9310_rtos', 'la9310_driver')) and 'rootfs' not in selected

        if 'rootfs' in selected:
            rootfs_choice = questionary.select(
                'Rootfs variant:',
                choices=ROOTFS_VARIANT_CHOICES,
                style=STYLE,
            ).ask()
            if rootfs_choice is None:
                sys.exit(1)

            include_rfnm, rfnm_load, usb_a = ask_rfnm_options()
            rootfs_fresh, rootfs_stages = ask_rootfs_build_mode(rootfs_choice)

            # Add stage 8 for RFNM when specific stages are selected
            if rootfs_choice == 'weston' and rootfs_stages is not None and include_rfnm and 8 not in rootfs_stages:
                rootfs_stages = sorted(rootfs_stages + [8])

        elif needs_deploy:
            rootfs_choice = questionary.select(
                'Rootfs variant (for artifact deployment):',
                choices=ROOTFS_VARIANT_CHOICES,
                style=STYLE,
            ).ask()
            if rootfs_choice is None:
                sys.exit(1)

            include_rfnm, rfnm_load, usb_a = ask_rfnm_options()

            rootfs_fresh = False
            rootfs_stages = [6, 7]
            if include_rfnm:
                rootfs_stages.append(8)

        else:
            rootfs_choice = 'weston'
            include_rfnm = False
            rfnm_load = False
            usb_a = 'device'
            rootfs_fresh = False
            rootfs_stages = None

        steps = {k: k in selected for k in
                 ('repos', 'uboot', 'kernel', 'dtbs', 'la9310_rtos', 'la9310_driver', 'rootfs')}
        if needs_deploy:
            steps['rootfs'] = True

        cfg = BuildConfig(
            steps=steps,
            rootfs_choice=rootfs_choice,
            rootfs_fresh=rootfs_fresh,
            rootfs_stages=rootfs_stages,
            include_rfnm_rootfs=include_rfnm,
            rfnm_load_on_startup=rfnm_load,
            usb_a_mode=usb_a,
        )

    # ── Shared post-processing (both full and partial) ─────────────────────────
    if action == 'build_flash':
        flash_choice, sd_device, usb_device = ask_flash()
        cfg.flash_choice = flash_choice
        cfg.sd_device = sd_device
        cfg.usb_device = usb_device

    # Ensure stage 7 (kernel modules) is present when flashing
    if cfg.flash_choice != 'none' and cfg.rootfs_stages is not None and cfg.rootfs_choice == 'weston':
        if 7 not in cfg.rootfs_stages:
            cfg.rootfs_stages = sorted(cfg.rootfs_stages + [7])
            print(f'Note: flashing selected; auto-adding rootfs stage 7.', flush=True)

    cfg.rootfs_script = ROOTFS_SCRIPTS[cfg.rootfs_choice]
    cfg.rootfs_name   = ROOTFS_NAMES.get(cfg.rootfs_choice, cfg.rootfs_choice.replace('_', ' ').capitalize())

    execute(cfg)


if __name__ == '__main__':
    main()
