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
        PLATFORM=win32
        GENERATOR=Ninja
        ;;
esac

echo "arch: $ARCH"
echo "platform: $PLATFORM"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

CONAN_REF="jaysinco/stable"
CONAN_PROFILE="$PROJECT_ROOT/config/$PLATFORM/$ARCH/conan.profile"
CONAN_CONF="tools.cmake.cmaketoolchain:generator=$GENERATOR"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo
            echo "Usage: build.sh [options] [targets]"
            echo
            echo "Options:"
            echo "  -i, --install    conan install"
            echo "  -s, --source     conan source"
            echo "  -b, --build      conan build"
            echo "  -h, --help       print command line options"
            echo
            exit 0
            ;;
        -s|--source)
            conan source .
            exit 0
            ;;
        -i|--install)
            conan install \
                --profile=$CONAN_PROFILE \
                --profile:build=$CONAN_PROFILE \
                --conf=$CONAN_CONF \
                . $CONAN_REF
            exit 0
            ;;
        -b|--build)
            conan build .
            exit 0
            ;;
        -*|--*)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

conan create \
    --profile=$CONAN_PROFILE \
    --profile:build=$CONAN_PROFILE \
    --conf=$CONAN_CONF \
    . $CONAN_REF
