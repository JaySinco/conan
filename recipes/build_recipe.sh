#!/bin/bash

set -e

case "$(uname -m)" in
    x86_64)   ARCH=x64 ;;
esac

case "$OSTYPE" in
    linux*)
        PLATFORM=linux
        GENERATOR=Ninja
        ;;
    msys*)
        PLATFORM=windows
        GENERATOR=Ninja
        ;;
esac

echo "arch: $ARCH"
echo "platform: $PLATFORM"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

conan create \
    --profile:build="$PROJECT_ROOT/profiles/$ARCH-$PLATFORM.profile" \
    --conf="tools.cmake.cmaketoolchain:generator=$GENERATOR" \
    . jaysinco/stable
