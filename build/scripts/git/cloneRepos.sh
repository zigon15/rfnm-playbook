#!/bin/sh

cd /work/build

# Clone a repo pinned to a specific commit (works regardless of how far HEAD has moved)
clone_at() {
    url=$1
    dir=$2
    sha=$3
    git clone "$url" --no-checkout --depth 1 --shallow-submodules "$dir"
    git -C "$dir" fetch origin "$sha" --depth 1
    git -C "$dir" -c advice.detachedHead=false checkout "$sha"
    git -C "$dir" submodule update --init --recursive --depth 1
}

clone_at https://github.com/rfnm/imx8mp-kernel.git   imx8mp-kernel   d0d8e7db2919192bb3f8c84c0dd3a115f9e516e6
clone_at https://github.com/rfnm/imx8mp-uboot        imx8mp-uboot    b59a410ae137fd98ff97ac0165a83364ee4eebfa
clone_at https://github.com/rfnm/la9310-driver.git   la9310-driver   fbfeaced919d76eb02817a5ae683037f104f6bc9
clone_at https://github.com/rfnm/la9310-freertos.git la9310-freertos 98253e7ebda79dcf420fb98bb60fd3b108cbc60e
clone_at https://github.com/nxp-imx/imx-atf.git      imx-atf         a266ff458c2526a6474036a5c6648be6fdc54fe3
clone_at https://github.com/rfnm/librfnm.git          librfnm         df85a47569370a3de7987b7c36d77e843ec7a41f
