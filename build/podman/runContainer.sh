mkdir -p build
podman run -it --rm -v $(pwd)/scripts:/work/scripts -v $(pwd)/build:/work/build rfnm-builder