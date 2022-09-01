#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
DEPS_DIR=$PROJECT_ROOT/deps

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo
            echo "Usage: build.sh [options]"
            echo
            echo "Options:"
            echo "  -m, --mount     mount vbox share"
            echo "  -u, --umount    unmount vbox share"
            echo "  -c, --clean     clean all build output"
            echo "  -h, --help      print command line options"
            echo
            exit 0
            ;;
        -m|--mount)
            mkdir -p ~/OneDrive/src
            sudo mount -t vboxsf -o ro,uid=$(id -u),gid=$(id -g) \
                share ~/OneDrive/src
            exit 0
            ;;
        -u|--umount)
            sudo umount -a -t vboxsf
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

$DEPS_DIR/gflags/build.sh && \
$DEPS_DIR/fmt/build.sh && \
$DEPS_DIR/spdlog/build.sh && \
echo done!