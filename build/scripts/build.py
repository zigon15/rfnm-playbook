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
        (1, 'debootstrap'),
        (2, 'configure'),
        (3, 'overlays'),
        (4, 'vivante        (download Vivante GPU + Hantro VPU userspace)'),
        (5, 'weston         (compile from source)'),
        (6, 'merge'),
        (7, 'kernel-modules (install .ko + NXP firmware)'),
    ],
}

# The merge stage number for each variant. Any selection that includes a
# non-merge stage automatically has the merge stage appended.
ROOTFS_MERGE_STAGE = {
    'weston': 6,
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

    # Merge always runs — exclude it from the checkbox so it can't be unticked.
    merge_stage = ROOTFS_MERGE_STAGE.get(rootfs_choice)
    build_stages = [(n, lbl) for n, lbl in stage_defs if n != merge_stage]

    choices = [
        questionary.Choice(f'{n} — {label}', value=n, checked=True)
        for n, label in build_stages
    ]
    selected = questionary.checkbox(
        'Stages to run:',
        choices=choices,
        style=STYLE,
    ).ask()
    if selected is None:
        sys.exit(1)
    if not selected:
        print('No stages selected — nothing to do.')
        sys.exit(0)

    # Always append the merge stage.
    if merge_stage is not None:
        selected.append(merge_stage)

    selected = sorted(selected)
    # If every stage is selected there's no point emitting STAGES= at all.
    all_nums = [n for n, _ in stage_defs]
    if selected == all_nums:
        return False, None
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


def apply_rfnm_rootfs_stage_policy(rootfs_choice, rootfs_stages, include_rfnm):
    """Ensure stage 7 runs when RFNM support is requested."""
    if rootfs_choice != 'weston':
        return rootfs_stages

    # All stages selected: stage 7 is included by default.
    if rootfs_stages is None:
        return None

    # If the user explicitly requested RFNM, ensure stage 7 runs because it now
    # performs both kernel module install and install.
    if include_rfnm and 7 not in rootfs_stages:
        rootfs_stages = sorted(rootfs_stages + [7])
    return rootfs_stages


def ensure_flash_safe_rootfs_stages(rootfs_choice, rootfs_stages, flash_choice, include_rfnm):
    """When flashing, include post-merge stages needed for bootable rootfs."""
    if flash_choice == 'none' or rootfs_stages is None:
        return rootfs_stages
    if rootfs_choice != 'weston':
        return rootfs_stages

    # Stage 7 installs kernel modules/firmware.
    required = [7]
    missing = [s for s in required if s not in rootfs_stages]
    if missing:
        rootfs_stages = sorted(rootfs_stages + missing)
        print(
            f'Note: flashing selected; auto-adding rootfs stages '
            f'{", ".join(str(s) for s in missing)}.',
            flush=True,
        )
    return rootfs_stages


def status_icon(ok):
    return '✅' if ok else '❌'


def rootfs_mode_label(rootfs_fresh, rootfs_stages):
    if rootfs_stages is not None:
        return f'Selected stages ({", ".join(str(s) for s in rootfs_stages)})'
    if rootfs_fresh:
        return 'Build from scratch'
    return 'All stages (reuse existing build dir)'


def weston_stage_states(rootfs_choice, rootfs_selected, rootfs_stages):
    if not rootfs_selected or rootfs_choice != 'weston':
        return []
    stage_defs = ROOTFS_STAGE_LABELS['weston']
    if rootfs_stages is None:
        run_set = {n for n, _ in stage_defs}
    else:
        run_set = set(rootfs_stages)
    return [(n, label, n in run_set) for n, label in stage_defs]


def print_build_summary(title, steps, rootfs_choice, rootfs_name, rootfs_fresh, rootfs_stages,
                        include_rfnm_rootfs, flash_choice, sd_device, usb_device,
                        elapsed_seconds=None):
    rootfs_selected = steps.get('rootfs', False)
    stage_states = weston_stage_states(rootfs_choice, rootfs_selected, rootfs_stages)
    overlays = {
        'base': os.path.isdir('/work/scripts/debian/rootfs-overlay/base'),
        'vivante': os.path.isdir('/work/scripts/debian/rootfs-overlay/vivante'),
        'rfnm': os.path.isdir('/work/scripts/debian/rootfs-overlay/rfnm'),
    }

    print(f'\n----- {title} -----')
    print(f'{status_icon(steps.get("repos", False))} Repos cloned')
    print(f'{status_icon(steps.get("uboot", False))} U-Boot + ATF rebuilt')
    print(f'{status_icon(steps.get("kernel", False))} Kernel rebuilt')
    print(f'{status_icon(steps.get("la9310_rtos", False))} LA9310 RTOS rebuilt')
    print(f'{status_icon(steps.get("la9310_driver", False))} LA9310 Driver rebuilt')

    if rootfs_selected:
        print(f'{status_icon(True)} Rootfs rebuilt ({rootfs_name})')
        print(f'   Mode: {rootfs_mode_label(rootfs_fresh, rootfs_stages)}')
        for num, label, ran in stage_states:
            print(f'   {status_icon(ran)} Stage {num} {label}')
            if num == 3:
                if ran:
                    print(f'      {status_icon(overlays["base"])} base overlay copied')
                    print(f'      {status_icon(overlays["vivante"])} vivante overlay copied')
                else:
                    print(f'      {status_icon(False)} base overlay copied (skipped)')
                    print(f'      {status_icon(False)} vivante overlay copied (skipped)')
        if include_rfnm_rootfs:
            print(f'   {status_icon(True)} RFNM artifacts install')
            print(f'      {status_icon(overlays["rfnm"])} rfnm overlay copied')
        else:
            print(f'   {status_icon(False)} RFNM artifacts install (skipped)')
    else:
        print(f'{status_icon(False)} Rootfs rebuilt ({rootfs_name}) (skipped)')

    if flash_choice == 'sd':
        print(f'✅ Flash SD ({sd_device})')
    elif flash_choice == 'sd_usb':
        print(f'✅ Flash SD ({sd_device}) + USB ({usb_device})')
    else:
        print('❌ Flash (skipped)')
    if elapsed_seconds is not None:
        minutes, seconds = divmod(int(elapsed_seconds), 60)
        hours, minutes = divmod(minutes, 60)
        print(f'Time taken: {hours:02d}:{minutes:02d}:{seconds:02d}')
    print('-------------------------')


# ── Shared: execute build + flash steps ───────────────────────────────────────

def execute(steps, rootfs_script, rootfs_name, rootfs_fresh, rootfs_stages,
            flash_choice, sd_device, usb_device, include_rfnm_rootfs, rootfs_choice):
    start_time = time.time()
    print_build_summary(
        'Build Plan', steps, rootfs_choice, rootfs_name, rootfs_fresh, rootfs_stages,
        include_rfnm_rootfs, flash_choice, sd_device, usb_device
    )

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
        cmd_parts = ['set -e', 'cd /work/scripts/debian']
        if rootfs_fresh:
            cmd_parts.append('./clean.sh')
        rfnm_support = '1' if include_rfnm_rootfs else '0'
        if rootfs_stages is not None:
            stages_str = ' '.join(str(s) for s in rootfs_stages)
            cmd_parts.append(f'RFNM_SUPPORT="{rfnm_support}" STAGES="{stages_str}" ./{rootfs_script}')
        else:
            cmd_parts.append(f'RFNM_SUPPORT="{rfnm_support}" ./{rootfs_script}')
        run_step(f'Building Debian Rootfs  ({rootfs_name})', '\n'.join(cmd_parts))

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

    print_build_summary(
        'Build Summary', steps, rootfs_choice, rootfs_name, rootfs_fresh, rootfs_stages,
        include_rfnm_rootfs, flash_choice, sd_device, usb_device,
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
        steps = {k: False for k in ('repos', 'uboot', 'kernel', 'la9310_rtos',
                                     'la9310_driver', 'rootfs', 'kernel_modules')}
        execute(steps, 'build_GalcoreGPU.sh', 'Base', False, None, flash_choice, sd_device, usb_device, False, 'base')
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

        rootfs_fresh, rootfs_stages = True, None  # full build always starts clean

        build_rfnm = ask_include_rfnm_support(default=True)
        include_rfnm_rootfs = build_rfnm
        rootfs_stages = apply_rfnm_rootfs_stage_policy(
            rootfs_choice, rootfs_stages, include_rfnm_rootfs
        )

        if action == 'build_flash':
            flash_choice, sd_device, usb_device = ask_flash()
        else:
            flash_choice, sd_device, usb_device = 'none', None, None

        rootfs_stages = ensure_flash_safe_rootfs_stages(
            rootfs_choice, rootfs_stages, flash_choice, include_rfnm_rootfs
        )

        steps = {
            'repos':         True,
            'uboot':         True,
            'kernel':        True,
            'la9310_rtos':   build_rfnm,
            'la9310_driver': build_rfnm,
            'rootfs':        True,
        }
        rootfs_script = ROOTFS_SCRIPTS[rootfs_choice]
        rootfs_name   = ROOTFS_NAMES.get(rootfs_choice, rootfs_choice.replace('_', ' ').capitalize())

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

        rootfs_choice = 'weston'  # default, unused if rootfs not selected
        rootfs_fresh, rootfs_stages = False, None

        if 'rootfs' in selected:
            rootfs_choice = questionary.select(
                'Rootfs variant:',
                choices=ROOTFS_VARIANT_CHOICES,
                style=STYLE,
            ).ask()
            if rootfs_choice is None:
                sys.exit(1)
            include_rfnm_rootfs = ask_include_rfnm_support(default=True)
            rootfs_fresh, rootfs_stages = ask_rootfs_build_mode(rootfs_choice)
            rootfs_stages = apply_rfnm_rootfs_stage_policy(
                rootfs_choice, rootfs_stages, include_rfnm_rootfs
            )
        else:
            include_rfnm_rootfs = False

        if action == 'build_flash':
            flash_choice, sd_device, usb_device = ask_flash()
        else:
            flash_choice, sd_device, usb_device = 'none', None, None

        rootfs_stages = ensure_flash_safe_rootfs_stages(
            rootfs_choice, rootfs_stages, flash_choice, include_rfnm_rootfs
        )

        steps = {k: k in selected for k in
                 ('repos', 'uboot', 'kernel', 'la9310_rtos', 'la9310_driver', 'rootfs')}
        rootfs_script = ROOTFS_SCRIPTS[rootfs_choice]
        rootfs_name   = ROOTFS_NAMES.get(rootfs_choice, rootfs_choice.replace('_', ' ').capitalize())

    execute(steps, rootfs_script, rootfs_name, rootfs_fresh, rootfs_stages,
            flash_choice, sd_device, usb_device, include_rfnm_rootfs, rootfs_choice)


if __name__ == '__main__':
    main()
