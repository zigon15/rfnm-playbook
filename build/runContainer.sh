mkdir -p build

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

podman run -it --privileged --rm \
    -v /dev:/dev \
    $ENV_ARGS \
    --network host \
    -v $(pwd)/scripts:/work/scripts \
    -v $(pwd)/build:/work/build \
    rfnm-builder "$@"