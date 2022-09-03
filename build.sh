#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
DEPS_DIR=$PROJECT_ROOT/deps
DOCKER_WORKSPACE_DIR=/workspace
DOCKER_IMAGE_TAG=build:v1

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo
            echo "Usage: build.sh [options]"
            echo
            echo "Options:"
            echo "  -m, --mount           mount vbox share"
            echo "  -u, --umount          unmount vbox share"
            echo "  -k, --docker-build    build image from dockerfile"
            echo "  -r, --docker-run      run dev container"
            echo "  -c, --clean           clean all build output"
            echo "  -h, --help            print command line options"
            echo
            exit 0
            ;;
        -m|--mount)
            mkdir -p $PROJECT_ROOT/src
            sudo mount -t vboxsf -o ro,uid=$(id -u),gid=$(id -g) \
                share $PROJECT_ROOT/src
            exit 0
            ;;
        -u|--umount)
            sudo umount -a -t vboxsf
            exit 0
            ;;
        -k|--docker-build)
            docker build --build-arg WORKSPACE_DIR=$DOCKER_WORKSPACE_DIR \
                -f $PROJECT_ROOT/Dockerfile \
                -t $DOCKER_IMAGE_TAG \
                $PROJECT_ROOT
            exit 0
            ;;
        -r|--docker-run)
            docker run -it --rm \
                -v $HOME/.ssh:/root/.ssh:ro \
                -v $HOME/.config/nvim:/root/.config/nvim:rw \
                -v $HOME/.local/share/nvim:/root/.local/share/nvim:rw \
                -v $PROJECT_ROOT:$DOCKER_WORKSPACE_DIR:rw \
                $DOCKER_IMAGE_TAG
            exit 0
            ;;
        -c|--clean)
            git clean -fdx
            exit 0
            ;;
        -*|--*)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done
