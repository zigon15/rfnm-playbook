mkdir -p build

DEVICE_ARG=""
ENV_ARG=""
if [ -n "$1" ]; then
    if [ -b "$1" ]; then
        # Map the specific device and the whole /dev for partition visibility
        DEVICE_ARG="--device $1:$1 -v /dev:/dev"
        ENV_ARG="-e FLASH_DEVICE=$1"
        echo "Mapping device: $1 (FLASH_DEVICE=$1)"
        shift
    else
        echo "Warning: $1 is not a block device. Continuing without mapping."
    fi
fi

podman run -it --privileged --rm \
    $DEVICE_ARG \
    $ENV_ARG \
    -v $(pwd)/scripts:/work/scripts \
    -v $(pwd)/build:/work/build \
    rfnm-builder "$@"