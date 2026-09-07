#!/bin/bash

source /unit_tests/test-utils.sh

print_name

if [ ! -e /dev/galcore ]; then
	echo gpu.sh not supported on $(platform)
	exit $STATUS
fi

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

if [ -n "${WAYLAND_DISPLAY:-}" ] && [ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
	unset WAYLAND_DISPLAY
fi

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
	for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
		[ -S "$socket" ] || continue
		export WAYLAND_DISPLAY="${socket##*/}"
		break
	done
fi

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
	echo "No Wayland socket found in $XDG_RUNTIME_DIR."
	echo "Check that weston.service is running: journalctl -u weston -b --no-pager"
	exit 1
fi

echo "Using Wayland display: $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
#
#Save current directory
#
pushd .
#
#run modprobe test
#
#gpu_mod_name=galcore.ko
#modprobe_test $gpu_mod_name
#
#run tests
#
cd /opt/viv_samples/vdk/ && ./tutorial3 -f 100 && cd - &>/dev/null
cd /opt/viv_samples/vdk/ && ./tutorial4_es20 -f 100 && cd - &>/dev/null
cd /opt/viv_samples/tiger/ && ./tiger && cd - &>/dev/null
echo press ESC to escape...
#
#remove gpu modules
#
#rmmod $gpu_mod_name
#restore the directory
#
popd
print_result
