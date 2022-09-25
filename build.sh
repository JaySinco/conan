#!/bin/bash

set -e

do_build_all=0
do_mount=0
do_unmount=0
do_vmware=0
do_build_docker=0
do_run_docker=0
do_list_ext=0
do_clone_repo=0
do_update_repo=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -h)
            echo
            echo "Usage: build.sh [options]"
            echo
            echo "Options:"
            echo "  -a   build all targets"
            echo "  -m   mount share [default: vbox]"
            echo "  -u   unmount share [default: vbox]"
            echo "  -v   u/mount vmware"
            echo "  -k   build docker"
            echo "  -r   run docker"
            echo "  -l   list vscode extensions"
            echo "  -n   clone all repo"
            echo "  -p   update all repo"
            echo "  -h   print command line options"
            echo
            exit 0
            ;;
        -a) do_build_all=1 && shift ;;
        -m) do_mount=1 && shift ;;
        -u) do_unmount=1 && shift ;;
        -v) do_vmware=1 && shift ;;
        -k) do_build_docker=1 && shift ;;
        -r) do_run_docker=1 && shift ;;
        -l) do_list_ext=1 && shift ;;
        -n) do_clone_repo=1 && shift ;;
        -p) do_update_repo=1 && shift ;;
        -*) echo "Unknown option: $1" && exit 1 ;;
    esac
done

case "$OSTYPE" in
    linux*)   os=linux ;;
    msys*)    os=windows ;;
esac

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
git_root="$(git rev-parse --show-toplevel)"
docker_image_tag=build:v1

function package() {
    local build_debug=$1
    local name=$2
    $git_root/recipes/build.sh $name -r && \
    if [ $build_debug -eq 1 ]; then
        $git_root/recipes/build.sh $name -r -d
    fi
}

function package_tools() {
    if [ $os = "windows" ]; then
        package 0 jom \
        && package 0 nasm \
        && package 0 strawberryperl
    fi
}

if [ $do_build_all -eq 1 ]; then
    echo start! \
    && package_tools \
    && package 1 gflags \
    && package 1 glog \
    && package 1 fmt \
    && package 1 spdlog \
    && package 0 boost \
    && package 1 glfw \
    && package 1 imgui \
    && package 1 implot \
    && package 1 catch2 \
    && package 0 qt \
    && package 0 expected-lite \
    && package 1 qhull \
    && package 1 lodepng \
    && package 1 libccd \
    && package 1 tinyobjloader \
    && package 1 tinyxml2 \
    && package 1 mujoco \
    && package 0 torch \
    && package 1 double-conversion \
    && package 1 bzip2 \
    && package 1 zlib \
    && package 0 openssl \
    && package 1 libevent \
    && package 1 zstd \
    && package 1 snappy \
    && package 1 lz4 \
    && package 1 folly \
    && package 0 argparse \
    && echo done!
    exit 0
fi

if [ $do_mount -eq 1 ]; then
    mkdir -p $git_root/src
    if [ $do_vmware -eq 0 ]; then
        sudo mount -t vboxsf -o ro,uid=$(id -u),gid=$(id -g) \
            share $git_root/src
    else
        vmhgfs-fuse -o ro,uid=$(id -u),gid=$(id -g) \
            .host:/share $git_root/src
    fi
    exit 0
fi

if [ $do_unmount -eq 1 ]; then
    if [ $do_vmware -eq 0 ]; then
        sudo umount -a -t vboxsf
    else
        sudo umount $git_root/src
    fi
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
        $HOME/.config/Code \
        $HOME/.vscode \
        $HOME/.conan
    docker run -it --rm \
        -e DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v $HOME/.ssh:/home/jaysinco/.ssh:ro \
        -v $HOME/.config/nvim:/home/jaysinco/.config/nvim:rw \
        -v $HOME/.local/share/nvim:/home/jaysinco/.local/share/nvim:rw \
        -v $HOME/.config/Code:/home/jaysinco/.config/Code:rw \
        -v $HOME/.vscode:/home/jaysinco/.vscode:rw \
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

function clone_repo() {
    if [ ! -d $1/.git ]; then
        echo "** CLONE $2 -b $3" \
        && mkdir -p $1 \
        && cd $1 \
        && git init \
        && git remote add origin $2 \
        && git fetch \
        && git checkout origin/$3 -b $3
    fi
}

if [ $do_clone_repo -eq 1 ]; then
    if [ $os = "windows" ]; then
        clone_repo $git_root/../Prototyping git@github.com:JaySinco/Prototyping.git master \
        && clone_repo $APPDATA/Code/User git@github.com:JaySinco/vscode.git master \
        && clone_repo $APPDATA/alacritty git@github.com:JaySinco/alacritty.git master
    else
        clone_repo $git_root/../Prototyping git@github.com:JaySinco/Prototyping.git master \
        && clone_repo $HOME/.config/Code/User git@github.com:JaySinco/vscode.git linux
    fi
    exit 0
fi

function update_repo() {
    echo "** UPDATE $1" \
        && cd $1 \
        && git pull
}

if [ $do_update_repo -eq 1 ]; then
    if [ $os = "windows" ]; then
        update_repo $git_root \
        && update_repo $git_root/../Prototyping \
        && update_repo $APPDATA/Code/User \
        && update_repo $APPDATA/alacritty
    else
        update_repo $git_root \
        && update_repo $git_root/../Prototyping \
        && update_repo $HOME/.config/Code/User
    fi
    exit 0
fi
