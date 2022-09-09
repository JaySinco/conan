#!/bin/bash

set -e

do_build_all=0
do_mount=0
do_unmount=0
do_build_docker=0
do_run_docker=0
do_list_ext=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -h)
            echo
            echo "Usage: build.sh [options]"
            echo
            echo "Options:"
            echo "  -a   build all targets"
            echo "  -m   mount vbox share"
            echo "  -u   unmount vbox share"
            echo "  -k   build docker"
            echo "  -r   run docker"
            echo "  -l   list vscode extensions"
            echo "  -h   print command line options"
            echo
            exit 0
            ;;
        -a) do_build_all=1 && shift ;;
        -m) do_mount=1 && shift ;;
        -u) do_unmount=1 && shift ;;
        -k) do_build_docker=1 && shift ;;
        -r) do_run_docker=1 && shift ;;
        -l) do_list_ext=1 && shift ;;
        -*) echo "Unknown option: $1" && exit 1 ;;
    esac
done

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
git_root="$(git rev-parse --show-toplevel)"
docker_image_tag=build:v1

function package() {
    local build_debug=$1
    local name=$2
    $git_root/recipes/build.sh $name -r
    if [ $build_debug -eq 1 ]; then
        $git_root/recipes/build.sh $name -r -d
    fi
}

if [ $do_build_all -eq 1 ]; then
    package 1 gflags
    package 1 fmt
    package 1 spdlog
    package 0 boost
    package 1 glfw
    package 1 imgui
    package 1 implot
    package 1 catch2
    package 0 qt
    package 0 expected-lite
    package 1 qhull
    package 1 lodepng
    package 1 libccd
    package 1 tinyobjloader
    package 1 tinyxml2
    package 1 mujoco
    package 0 torch
    exit 0
fi

if [ $do_mount -eq 1 ]; then
    mkdir -p $git_root/src
    sudo mount -t vboxsf -o ro,uid=$(id -u),gid=$(id -g) \
        share $git_root/src
    exit 0
fi

if [ $do_unmount -eq 1 ]; then
    sudo umount -a -t vboxsf
    exit 0
fi

if [ $do_build_docker -eq 1 ]; then
    docker build \
        -f $git_root/Dockerfile \
        -t $docker_image_tag \
        $git_root
    exit 0
fi

if [ $do_run_docker -eq 1 ]; then
    mkdir -p \
        $HOME/.ssh \
        $HOME/.config/nvim \
        $HOME/.local/share/nvim \
        $HOME/.conan
    docker run -it --rm \
        -e DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v $HOME/.ssh:/home/jaysinco/.ssh:ro \
        -v $HOME/.config/nvim:/home/jaysinco/.config/nvim:rw \
        -v $HOME/.local/share/nvim:/home/jaysinco/.local/share/nvim:rw \
        -v $HOME/.conan:/home/jaysinco/.conan:rw \
        -v $git_root:/home/jaysinco/workspace:rw \
        $docker_image_tag
    exit 0
fi

if [ $do_list_ext -eq 1 ]; then
    code --list-extensions | jq -R -s '{recommendations:split("\n")[:-1]}' \
        --indent 4 > $git_root/.vscode/extensions.json
    exit 0
fi
