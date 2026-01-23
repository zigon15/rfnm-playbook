mkdir -p build
podman run -it --privileged --rm -v $(pwd)/scripts:/work/scripts -v $(pwd)/build:/work/build rfnm-builder