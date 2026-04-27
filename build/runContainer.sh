SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BRANCH_NAME="$(git -C "$SCRIPT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

mkdir -p "build/${BRANCH_NAME}"

ENV_ARGS=""
if [ -n "$1" ]; then
    if [ -b "$1" ]; then
        ENV_ARGS="-e FLASH_DEVICE=$1"
        echo "FLASH_DEVICE=$1"
        shift
    else
        echo "Warning: $1 is not a block device. Continuing without FLASH_DEVICE."
    fi
fi

echo "Building from branch: ${BRANCH_NAME}"

podman run -it --privileged --rm \
    -v /dev:/dev \
    $ENV_ARGS \
    --network host \
    -e BRANCH_NAME="$BRANCH_NAME" \
    -v "$(pwd)/scripts:/work/scripts" \
    -v "$(pwd)/build/${BRANCH_NAME}:/work/build" \
    rfnm-builder "$@"
