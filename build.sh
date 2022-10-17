#!/bin/bash

set -e

do_build_all=0
do_mount=0
do_unmount=0
do_vmware=0
do_build_docker=0
do_run_docker=0
do_list_ext=0
do_install_ext=0
do_env_setup=0
do_update_repo=0
do_status_repo=0

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
            echo "  -i   install vscode extensions"
            echo "  -n   env setup"
            echo "  -p   pull/push all repo"
            echo "  -s   list all repo status"
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
        -i) do_install_ext=1 && shift ;;
        -n) do_env_setup=1 && shift ;;
        -p) do_update_repo=1 && shift ;;
        -s) do_status_repo=1 && shift ;;
         *) echo "Unknown option: $1" && exit 1 ;;
    esac
done

case "$OSTYPE" in
    linux*)   os=linux ;;
    msys*)    os=windows ;;
esac

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
git_root="$(git rev-parse --show-toplevel)"
linux_res_dir=$git_root/../dev-setup/linux
windows_res_dir=$git_root/../dev-setup/windows
docker_image_tag=build:v1

if [ $os = "linux" ]; then
    source_repo=$linux_res_dir/src
    nvim_config_dir=$HOME/.config/nvim
    nvim_data_dir=$HOME/.local/share/nvim
    vscode_config_dir=$HOME/.config/Code
    vscode_config_branch=linux
elif [ $os = "windows" ]; then
    source_repo=$USERPROFILE/OneDrive/src
    nvim_config_dir=$LOCALAPPDATA/nvim
    nvim_data_dir=$LOCALAPPDATA/nvim-data
    vscode_config_dir=$APPDATA/Code
    vscode_config_branch=master
fi

function package() {
    local build_debug=$1
    local name=$2
    $git_root/../dev-setup/recipes/build.sh $name -r && \
    if [ $build_debug -eq 1 ]; then
        $git_root/../dev-setup/recipes/build.sh $name -r -d
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
    && package 1 lz4 \
    && package 0 argparse \
    && package 0 range-v3 \
    && package 1 libiconv \
    && echo done!
    exit 0
fi

if [ $do_mount -eq 1 ]; then
    mkdir -p $source_repo
    if [ $do_vmware -eq 0 ]; then
        sudo mount -t vboxsf -o ro,uid=$(id -u),gid=$(id -g) \
            share $source_repo
    else
        # apt install open-vm-tools open-vm-tools-desktop
        vmhgfs-fuse -o ro,uid=$(id -u),gid=$(id -g) \
            .host:/share $source_repo
    fi
    exit 0
fi

if [ $do_unmount -eq 1 ]; then
    if [ $do_vmware -eq 0 ]; then
        sudo umount -a -t vboxsf
    else
        sudo umount $source_repo
    fi
    exit 0
fi

if [ $do_build_docker -eq 1 ]; then
    docker build \
        -f $linux_res_dir/Dockerfile \
        -t $docker_image_tag \
        $linux_res_dir
    exit 0
fi

if [ $do_run_docker -eq 1 ]; then
    mkdir -p \
        $HOME/.ssh \
        $nvim_config_dir \
        $nvim_data_dir \
        $vscode_config_dir \
        $HOME/.vscode \
        $HOME/.conan
    docker run -it --rm \
        --security-opt seccomp=unconfined \
        --shm-size=1G \
        -e DISPLAY=$DISPLAY \
        -e LOCAL_UID=$(id -u) \
        -e LOCAL_GID=$(id -g) \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v $HOME/.ssh:/home/jaysinco/.ssh:ro \
        -v $nvim_config_dir:/home/jaysinco/.config/nvim:rw \
        -v $nvim_data_dir:/home/jaysinco/.local/share/nvim:rw \
        -v $vscode_config_dir:/home/jaysinco/.config/Code:rw \
        -v $HOME/.vscode:/home/jaysinco/.vscode:rw \
        -v $HOME/.conan:/home/jaysinco/.conan:rw \
        -v $git_root/../dev-setup:/home/jaysinco/dev-setup:rw \
        -v $git_root/../Prototyping:/home/jaysinco/Prototyping:rw \
        $docker_image_tag
    exit 0
fi

if [ $do_list_ext -eq 1 ]; then
    code --list-extensions | jq -R -s '{recommendations:split("\n")[:-1]}' \
        --indent 4 > $git_root/../dev-setup/.vscode/extensions.json
    exit 0
fi

if [ $do_install_ext -eq 1 ]; then
    for ext in $(jq -r '.recommendations[]' < $git_root/../dev-setup/.vscode/extensions.json); do
        code --install-extension `echo $ext | sed 's/\r$//'`
    done
    exit 0
fi

function clone_repo() {
    if [ ! -d "$1/.git" ]; then
        echo "** CLONE $2 -b $3" \
        && mkdir -p "$1" \
        && cd "$1" \
        && git init \
        && git remote add origin $2 \
        && git fetch \
        && git checkout origin/$3 -b $3 \
        && git config user.name jaysinco \
        && git config user.email jaysinco@163.com
    fi
}

if [ $do_env_setup -eq 1 ]; then
    if [ $os = "windows" ]; then
        $windows_res_dir/set-env.sh \
        && clone_repo $LOCALAPPDATA/Microsoft/Windows\ Terminal git@github.com:JaySinco/windows-terminal.git master
    else
        if [ ! -f "$HOME/.local/share/fonts/Fira Mono Regular Nerd Font Complete.otf" ]; then
            mkdir -p $HOME/.local/share/fonts \
            && unzip $source_repo/FiraMono.zip -d $HOME/.local/share/fonts
        fi
    fi \
    && clone_repo $git_root/../Prototyping git@github.com:JaySinco/Prototyping.git master \
    && clone_repo $vscode_config_dir/User git@github.com:JaySinco/vscode.git $vscode_config_branch \
    && clone_repo $nvim_config_dir git@github.com:JaySinco/nvim.git master && \
    if [ ! -d $nvim_data_dir/site ]; then
        mkdir -p $nvim_data_dir \
        && unzip -q $source_repo/nvim-data-site-v2022.09.24-$os.zip -d $nvim_data_dir
    fi
    exit 0
fi

function update_repo() {
    cd "$1"
    echo "pull* "`realpath "$1"`
    git pull
    git merge-base --is-ancestor HEAD @{u}
    if [ $? -ne 0 ]; then
        echo "push*" `realpath "$1"`
        git push
    fi
}

if [ $do_update_repo -eq 1 ]; then
    if [ $os = "windows" ]; then
        update_repo $LOCALAPPDATA/Microsoft/Windows\ Terminal
    fi \
    && update_repo $git_root/../dev-setup \
    && update_repo $git_root/../Prototyping \
    && update_repo $vscode_config_dir/User \
    && update_repo $nvim_config_dir
    exit 0
fi

function status_repo() {
    cd "$1"
    if [ ! -z "$(git status --porcelain)" ]; then
        echo ================== \
        && echo `realpath "$1"` \
        && echo ================== \
        && git status --porcelain \
        && echo
    fi
}

if [ $do_status_repo -eq 1 ]; then
    status_repo $git_root/../dev-setup \
    && status_repo $git_root/../Prototyping \
    && status_repo $vscode_config_dir/User \
    && status_repo $nvim_config_dir && \
    if [ $os = "windows" ]; then \
        status_repo $LOCALAPPDATA/Microsoft/Windows\ Terminal
    fi
    exit 0
fi