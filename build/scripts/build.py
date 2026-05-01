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
import yaml
import questionary
from questionary import Style

# ── ANSI colours ──────────────────────────────────────────────────────────────
CYAN  = '\033[0;36m'
GREEN = '\033[0;32m'
RED   = '\033[0;31m'
BOLD  = '\033[1m'
NC    = '\033[0m'
SECTION_QMARK = '-> ?'

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


def echo_prompt_section(label):
    print(f'\n{BOLD}{label}{NC}', flush=True)


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


def ask_device(prompt, env_var, qmark='?'):
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
            qmark=qmark,
            style=STYLE,
        ).ask()
        if answer is None:
            sys.exit(1)
        if answer != MANUAL:
            return answer

    # Manual entry (fallback or user chose it)
    answer = questionary.text(prompt, default=default, qmark=qmark, style=STYLE).ask()
    if not answer:
        sys.exit(1)
    return answer


def ask_flash():
    echo_prompt_section('Flash')
    flash_choice = questionary.select(
        'After building:',
        choices=[
            questionary.Choice('Just build - no flashing',                            value='none'),
            questionary.Choice('Flash SD - everything on SD card',                      value='sd'),
            questionary.Choice('Flash SD + USB - U-Boot on SD, kernel+rootfs on USB',   value='sd_usb'),
        ],
        qmark=SECTION_QMARK,
        style=STYLE,
    ).ask()
    if flash_choice is None:
        sys.exit(1)

    sd_device  = None
    usb_device = None

    if flash_choice in ('sd', 'sd_usb'):
        sd_device = ask_device('SD card device:', 'FLASH_DEVICE', qmark=SECTION_QMARK)

    if flash_choice == 'sd_usb':
        usb_device = ask_device('USB drive device:', 'USB_DEVICE', qmark=SECTION_QMARK)

    return flash_choice, sd_device, usb_device


# ── Rootfs stage selection ────────────────────────────────────────────────────

# Stage labels for variants that support staged builds. Variants not listed
# here fall back to a simple fresh/skip-clean choice.
ROOTFS_STAGE_LABELS = {
    'weston': [
        (1, 'debootstrap + configure base system'),
        (2, 'download Vivante GPU + Hantro VPU'),
        (3, 'compile weston-imx'),
        (4, 'run optional stages'),
        (5, 'merge + overlays (assemble final rootfs)'),
        (6, 'install kernel modules + NXP firmware'),
    ],
    'base': [
        (1, 'debootstrap + configure base system'),
        (2, 'download Vivante GPU + Hantro VPU'),
        (5, 'merge + overlays (assemble final rootfs)'),
        (6, 'install kernel modules + NXP firmware'),
    ],
}

OPTIONAL_STAGE_LABELS = {
    'weston': [('gpu-sdk', 'compile GPU SDK (gtec-demo-framework)')],
}


def ask_rootfs_build_mode(rootfs_choice, qmark='?'):
    """Ask which rootfs stages to run. Returns (stages: list[int]|None, optionals: list[str]).

    stages=None means run all stages (used for non-staged variants).
    """
    stage_defs = ROOTFS_STAGE_LABELS.get(rootfs_choice)

    if stage_defs is None:
        return None, []

    mandatory_stages = {5, 6}
    if rootfs_choice == 'weston':
        mandatory_stages.add(4)

    checkbox_stages = [(n, lbl) for n, lbl in stage_defs if n not in mandatory_stages]
    optional_defs = OPTIONAL_STAGE_LABELS.get(rootfs_choice, [])

    choices = [questionary.Choice(f'{n} — {label}', value=n, checked=True) for n, label in checkbox_stages]
    for key, label in optional_defs:
        choices.append(questionary.Choice(label, value=key, checked=False))

    selected = questionary.checkbox(
        'Rootfs stages to run:',
        choices=choices,
        instruction='',
        qmark=qmark,
        style=STYLE,
    ).ask()
    if selected is None:
        sys.exit(1)

    mandatory = sorted(set(n for n in selected if isinstance(n, int)) | mandatory_stages)
    optionals = [s for s in selected if isinstance(s, str)]
    return mandatory, optionals


def all_rootfs_stages(rootfs_choice, include_rfnm=False):
    stage_defs = ROOTFS_STAGE_LABELS.get(rootfs_choice)
    if stage_defs is None:
        return None
    stages = [n for n, _ in stage_defs]
    if include_rfnm and 7 not in stages:
        stages.append(7)
    return sorted(stages)


def ask_clean_rootfs(default=False, qmark='?'):
    fresh = questionary.confirm(
        'Clean existing rootfs build first?',
        default=default,
        qmark=qmark,
        style=STYLE,
    ).ask()
    if fresh is None:
        sys.exit(1)
    return fresh


def ask_clean_kernel(default=True, qmark='?'):
    clean = questionary.confirm(
        'Clean existing kernel tree first?',
        default=default,
        qmark=qmark,
        style=STYLE,
    ).ask()
    if clean is None:
        sys.exit(1)
    return clean


def ask_include_rfnm_support(default=True, qmark='?'):
    include = questionary.confirm(
        'Include RFNM support in rootfs (overlay + LA9310 artifacts)?',
        default=default,
        qmark=qmark,
        style=STYLE,
    ).ask()
    if include is None:
        sys.exit(1)
    return include


def ask_rfnm_load_on_startup(default=True, qmark='?'):
    return questionary.confirm(
        'Load RFNM drivers on startup?',
        default=default,
        qmark=qmark,
        style=STYLE,
    ).ask()


def ask_usb_a_mode(qmark='?'):
    return questionary.select(
        'USB-A port mode:',
        choices=[
            questionary.Choice('Device (USB boost)', value='device'),
            questionary.Choice('Host (keyboard/mouse)', value='host'),
        ],
        default='device',
        qmark=qmark,
        style=STYLE,
    ).ask()


def ask_weston_service_enabled(default=True, qmark='?'):
    enabled = questionary.confirm(
        'Enable Weston service by default?',
        default=default,
        qmark=qmark,
        style=STYLE,
    ).ask()
    if enabled is None:
        sys.exit(1)
    return enabled


def ask_rfnm_options(default_include=True, qmark='?'):
    """Ask all RFNM-related questions. Returns (include, load_on_startup, usb_a_mode)."""
    include = ask_include_rfnm_support(default=default_include, qmark=qmark)
    if include:
        return include, ask_rfnm_load_on_startup(qmark=qmark), ask_usb_a_mode(qmark=qmark)
    return include, False, 'device'


# ── Last-build config save/load ───────────────────────────────────────────────

def _script_dir():
    return os.path.dirname(os.path.abspath(__file__))


def config_path():
    return os.path.join(_script_dir(), '.last_build_config.yaml')


def save_build_config(cfg):
    """Save non-flash build config fields to YAML."""
    data = {
        'steps': cfg.steps,
        'kernel_clean': cfg.kernel_clean,
        'rootfs_choice': cfg.rootfs_choice,
        'rootfs_fresh': cfg.rootfs_fresh,
        'rootfs_stages': cfg.rootfs_stages,
        'selected_optionals': cfg.selected_optionals,
        'weston_service_enabled': cfg.weston_service_enabled,
        'include_rfnm_rootfs': cfg.include_rfnm_rootfs,
        'rfnm_load_on_startup': cfg.rfnm_load_on_startup,
        'usb_a_mode': cfg.usb_a_mode,
    }
    with open(config_path(), 'w') as f:
        yaml.dump(data, f, default_flow_style=False)


def load_build_config():
    """Load last build config from YAML, or None if missing/corrupt."""
    path = config_path()
    if not os.path.isfile(path):
        return None
    try:
        with open(path) as f:
            data = yaml.safe_load(f)
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    cfg = BuildConfig()
    cfg.steps = data.get('steps', {k: False for k in cfg.steps})
    cfg.kernel_clean = data.get('kernel_clean', True)
    cfg.rootfs_choice = data.get('rootfs_choice', 'weston')
    cfg.rootfs_fresh = data.get('rootfs_fresh', False)
    cfg.rootfs_stages = data.get('rootfs_stages', None)
    cfg.selected_optionals = data.get('selected_optionals', [])
    cfg.weston_service_enabled = data.get('weston_service_enabled', True)
    cfg.include_rfnm_rootfs = data.get('include_rfnm_rootfs', False)
    cfg.rfnm_load_on_startup = data.get('rfnm_load_on_startup', False)
    cfg.usb_a_mode = data.get('usb_a_mode', 'device')
    # Flash fields: never saved, always default to no-flash
    cfg.flash_choice = 'none'
    cfg.sd_device = None
    cfg.usb_device = None
    return cfg


def ask_reuse_last():
    """Ask whether to reuse the last build config."""
    if not os.path.isfile(config_path()):
        return None
    answer = questionary.confirm(
        'Build same as last time?',
        default=True,
        style=STYLE,
    ).ask()
    if answer is None:
        sys.exit(1)
    return answer


# ── Build configuration ───────────────────────────────────────────────────────

@dataclass
class BuildConfig:
    steps: dict = field(default_factory=lambda: {
        k: False for k in ('repos', 'uboot', 'kernel', 'dtbs',
                           'la9310_rtos', 'la9310_driver', 'rootfs')
    })
    kernel_clean: bool = True
    rootfs_choice: str = 'weston'
    rootfs_script: str = 'build_GalcoreGPU.sh'
    rootfs_name: str = 'Base'
    rootfs_fresh: bool = False
    rootfs_stages: Optional[list] = None
    selected_optionals: list = field(default_factory=list)
    weston_service_enabled: bool = True
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

    # Build stage state list for staged rootfs variants.
    stage_states = []
    optional_states = []
    if rootfs_selected and cfg.rootfs_choice in ROOTFS_STAGE_LABELS:
        stage_defs = ROOTFS_STAGE_LABELS[cfg.rootfs_choice]
        run_set = {n for n, _ in stage_defs} if cfg.rootfs_stages is None else set(cfg.rootfs_stages)
        stage_states = [(n, label, n in run_set) for n, label in stage_defs]
        optional_defs = OPTIONAL_STAGE_LABELS.get(cfg.rootfs_choice, [])
        optional_states = [(key, label, key in cfg.selected_optionals) for key, label in optional_defs]

    # Rootfs mode label
    if cfg.rootfs_stages is not None:
        stage_label = f'Selected stages ({", ".join(str(s) for s in cfg.rootfs_stages)})'
        mode_label = f'Clean + {stage_label}' if cfg.rootfs_fresh else stage_label
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
    if cfg.steps.get('kernel', False):
        print(f'      Clean first: {"yes" if cfg.kernel_clean else "no"}')
    dtbs_ok = cfg.steps.get('dtbs', False) or cfg.steps.get('kernel', False)
    print(f'   {status_icon(dtbs_ok)} Device Trees rebuilt')
    print(f'{status_icon(cfg.steps.get("la9310_rtos", False))} LA9310 RTOS rebuilt')
    print(f'{status_icon(cfg.steps.get("la9310_driver", False))} LA9310 Driver rebuilt')

    if rootfs_selected:
        print(f'{status_icon(True)} Rootfs rebuilt ({cfg.rootfs_name})')
        print(f'   Mode: {mode_label}')
        for num, label, ran in stage_states:
            print(f'   {status_icon(ran)} Stage {num} — {label}')
            if cfg.rootfs_choice == 'weston' and num == 3:
                print(f'      Weston service enabled by default: {"yes" if cfg.weston_service_enabled else "no"}')
        for key, label, ran in optional_states:
            print(f'   {status_icon(ran)} {label} (optional)')
        if cfg.include_rfnm_rootfs:
            print(f'   {status_icon(True)} Stage 7 — install RFNM LA9310 driver + firmware')
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
        cmd_parts = ['set -e', 'cd /work/scripts/kernel']
        if cfg.kernel_clean:
            cmd_parts.append('./clean.sh')
        cmd_parts.append('./build_GalcoreGPU.sh')
        run_step('Building Linux Kernel', '\n'.join(cmd_parts))

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
        weston_service = '1' if cfg.weston_service_enabled else '0'
        optional_str = ' '.join(cfg.selected_optionals)
        if cfg.rootfs_stages is not None:
            stages_str = ' '.join(str(s) for s in cfg.rootfs_stages)
            cmd_parts.append(f'RFNM_SUPPORT="{rfnm_support}" RFNM_LOAD_ON_STARTUP="{rfnm_load}" USB_A_MODE="{cfg.usb_a_mode}" WESTON_ENABLE_SERVICE="{weston_service}" OPTIONAL_STAGES="{optional_str}" STAGES="{stages_str}" ./{cfg.rootfs_script}')
        else:
            cmd_parts.append(f'RFNM_SUPPORT="{rfnm_support}" RFNM_LOAD_ON_STARTUP="{rfnm_load}" USB_A_MODE="{cfg.usb_a_mode}" WESTON_ENABLE_SERVICE="{weston_service}" OPTIONAL_STAGES="{optional_str}" ./{cfg.rootfs_script}')
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
    'base':    'build_GalcoreGPU.sh',
}

ROOTFS_NAMES = {
    'weston':  'Weston  (Wayland compositor + Vivante GL)',
    'base':    'Base',
}

ROOTFS_VARIANT_CHOICES = [
    questionary.Choice('Weston - Wayland compositor + Vivante GL', value='weston'),
    questionary.Choice('Base - Headless',                          value='base'),
]


def main():
    print(f'\n{BOLD}{CYAN}╔══════════════════════════════════════════╗{NC}')
    print(f'{BOLD}{CYAN}║    RFNM Linux Build Configuration        ║{NC}')
    print(f'{BOLD}{CYAN}╚══════════════════════════════════════════╝{NC}\n')

    # ── Reuse last build config? ───────────────────────────────────────────────
    reuse = ask_reuse_last()
    if reuse:
        cfg = load_build_config()
        if cfg is not None:
            if cfg.rootfs_choice not in ROOTFS_SCRIPTS:
                cfg.rootfs_choice = 'base'
            if cfg.rootfs_choice in ROOTFS_STAGE_LABELS and cfg.rootfs_stages is None:
                cfg.rootfs_stages = all_rootfs_stages(
                    cfg.rootfs_choice,
                    include_rfnm=cfg.include_rfnm_rootfs,
                )
            cfg.rootfs_script = ROOTFS_SCRIPTS[cfg.rootfs_choice]
            cfg.rootfs_name   = ROOTFS_NAMES.get(cfg.rootfs_choice, cfg.rootfs_choice.replace('_', ' ').capitalize())
            flash_choice, sd_device, usb_device = ask_flash()
            cfg.flash_choice = flash_choice
            cfg.sd_device = sd_device
            cfg.usb_device = usb_device
            if cfg.flash_choice != 'none' and cfg.rootfs_stages is not None and cfg.rootfs_choice in ROOTFS_STAGE_LABELS:
                if 6 not in cfg.rootfs_stages:
                    cfg.rootfs_stages = sorted(cfg.rootfs_stages + [6])
                    print(f'Note: flashing selected; auto-adding rootfs stage 6.', flush=True)
            execute(cfg)
            return
        print('Saved config not found or corrupt — continuing with interactive setup.\n', flush=True)

    # ── Top-level action ───────────────────────────────────────────────────────
    action = questionary.select(
        'What do you want to do?',
        choices=[
            questionary.Choice('Build - compile only',                          value='build'),
            questionary.Choice('Build and flash - compile then flash',                value='build_flash'),
            questionary.Choice('Flash - flash pre-built artifacts now',               value='flash'),
        ],
        style=STYLE,
    ).ask()
    if action is None:
        sys.exit(1)

    # ── Flash only ─────────────────────────────────────────────────────────────
    if action == 'flash':
        echo_prompt_section('Flash')
        flash_choice = questionary.select(
            'Flash target:',
            choices=[
                questionary.Choice('Flash SD - everything on SD card',                      value='sd'),
                questionary.Choice('Flash SD + USB - U-Boot on SD, kernel+rootfs on USB',   value='sd_usb'),
            ],
            qmark=SECTION_QMARK,
            style=STYLE,
        ).ask()
        if flash_choice is None:
            sys.exit(1)
        sd_device = ask_device('SD card device:', 'FLASH_DEVICE', qmark=SECTION_QMARK)
        usb_device = ask_device('USB drive device:', 'USB_DEVICE', qmark=SECTION_QMARK) if flash_choice == 'sd_usb' else None
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

    # ── Component selection ─────────────────────────────────────────────────────
    selected = questionary.checkbox(
        'Select components to rebuild:',
        choices=[
            questionary.Choice('Prepare repos (clone + firmware + apply patches)', value='repos',        checked=True),
            questionary.Choice('U-Boot + ATF',                                    value='uboot',        checked=True),
            questionary.Choice('Linux Kernel',                                    value='kernel',       checked=True),
            questionary.Choice('LA9310 RTOS Firmware',                            value='la9310_rtos',  checked=True),
            questionary.Choice('LA9310 Kernel Driver',                            value='la9310_driver',checked=True),
            questionary.Choice('Debian Rootfs',                                   value='rootfs',       checked=True),
        ],
        style=STYLE,
    ).ask()
    if selected is None:
        sys.exit(1)
    if not selected:
        print('Nothing selected — exiting.')
        sys.exit(0)

    kernel_mode = 'full'
    kernel_clean = True
    if 'kernel' in selected:
        echo_prompt_section('Kernel')
        kernel_mode = questionary.select(
            'Kernel build mode:',
            choices=[
                questionary.Choice('Full build - build Image, DTBs + modules', value='full'),
                questionary.Choice('Device Tree - build DTBs only (fast)',              value='dtbs'),
            ],
            default='full',
            qmark=SECTION_QMARK,
            style=STYLE,
        ).ask()
        if kernel_mode is None:
            sys.exit(1)
        if kernel_mode == 'dtbs':
            selected.remove('kernel')
            selected.append('dtbs')
            kernel_clean = False
        else:
            kernel_clean = ask_clean_kernel(default=True, qmark=SECTION_QMARK)

    needs_deploy = any(c in selected for c in ('kernel', 'dtbs', 'la9310_rtos', 'la9310_driver')) and 'rootfs' not in selected

    if 'rootfs' in selected:
        echo_prompt_section('Rootfs')
        rootfs_fresh = ask_clean_rootfs(default=True, qmark=SECTION_QMARK)
        rootfs_choice = questionary.select(
            'Rootfs variant:',
            choices=ROOTFS_VARIANT_CHOICES,
            qmark=SECTION_QMARK,
            style=STYLE,
        ).ask()
        if rootfs_choice is None:
            sys.exit(1)

        weston_service_enabled = True
        if rootfs_choice == 'weston':
            weston_service_enabled = ask_weston_service_enabled(qmark=SECTION_QMARK)
        include_rfnm, rfnm_load, usb_a = ask_rfnm_options(qmark=SECTION_QMARK)
        rootfs_stages, selected_optionals = ask_rootfs_build_mode(rootfs_choice, qmark=SECTION_QMARK)

        # Add stage 7 for RFNM when specific stages are selected.
        if rootfs_choice in ROOTFS_STAGE_LABELS and rootfs_stages is not None and include_rfnm and 7 not in rootfs_stages:
            rootfs_stages = sorted(rootfs_stages + [7])

    elif needs_deploy:
        echo_prompt_section('Rootfs')
        rootfs_choice = questionary.select(
            'Rootfs variant (for artifact deployment):',
            choices=ROOTFS_VARIANT_CHOICES,
            qmark=SECTION_QMARK,
            style=STYLE,
        ).ask()
        if rootfs_choice is None:
            sys.exit(1)

        weston_service_enabled = True
        if rootfs_choice == 'weston':
            weston_service_enabled = ask_weston_service_enabled(qmark=SECTION_QMARK)
        include_rfnm, rfnm_load, usb_a = ask_rfnm_options(qmark=SECTION_QMARK)

        rootfs_fresh = False
        rootfs_stages = [5, 6]
        selected_optionals = []
        if include_rfnm:
            rootfs_stages.append(7)

    else:
        rootfs_choice = 'weston'
        include_rfnm = False
        rfnm_load = False
        usb_a = 'device'
        weston_service_enabled = True
        rootfs_fresh = False
        rootfs_stages = None
        selected_optionals = []

    steps = {k: k in selected for k in
             ('repos', 'uboot', 'kernel', 'dtbs', 'la9310_rtos', 'la9310_driver', 'rootfs')}
    if needs_deploy:
        steps['rootfs'] = True

    cfg = BuildConfig(
        steps=steps,
        kernel_clean=kernel_clean,
        rootfs_choice=rootfs_choice,
        rootfs_fresh=rootfs_fresh,
        rootfs_stages=rootfs_stages,
        selected_optionals=selected_optionals,
        weston_service_enabled=weston_service_enabled,
        include_rfnm_rootfs=include_rfnm,
        rfnm_load_on_startup=rfnm_load,
        usb_a_mode=usb_a,
    )

    # ── Shared post-processing ─────────────────────────────────────────────────
    if action == 'build_flash':
        flash_choice, sd_device, usb_device = ask_flash()
        cfg.flash_choice = flash_choice
        cfg.sd_device = sd_device
        cfg.usb_device = usb_device

    # Ensure stage 6 (kernel modules) is present when flashing.
    if cfg.flash_choice != 'none' and cfg.rootfs_stages is not None and cfg.rootfs_choice in ROOTFS_STAGE_LABELS:
        if 6 not in cfg.rootfs_stages:
            cfg.rootfs_stages = sorted(cfg.rootfs_stages + [6])
            print(f'Note: flashing selected; auto-adding rootfs stage 6.', flush=True)

    cfg.rootfs_script = ROOTFS_SCRIPTS[cfg.rootfs_choice]
    cfg.rootfs_name   = ROOTFS_NAMES.get(cfg.rootfs_choice, cfg.rootfs_choice.replace('_', ' ').capitalize())

    save_build_config(cfg)
    execute(cfg)


if __name__ == '__main__':
    main()
