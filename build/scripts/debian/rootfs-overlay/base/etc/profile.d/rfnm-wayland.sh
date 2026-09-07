export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
	for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
		[ -S "$socket" ] || continue
		export WAYLAND_DISPLAY="${socket##*/}"
		break
	done
fi
