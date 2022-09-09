#!/bin/bash

set -e

build_targets=()
build_debug=0

do_clean=0
do_source=0
do_install=0
do_build=0
do_export=0
do_export_package=0
do_create=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -h)
            echo
            echo "Usage: build.sh [targets] [actions] [configs]"
            echo
            echo "Actions:"
            echo "  -c   clean output"
            echo "  -s   conan source"
            echo "  -i   conan install"
            echo "  -b   conan build"
            echo "  -e   conan export"
            echo "  -p   conan export-pkg"
            echo "  -r   create package by combining all actions"
            echo
            echo "Configs:"
            echo "  -d   build debug version"
            echo "  -h   print command line options"
            echo
            exit 0
            ;;
        -c) do_clean=1 && shift ;;
        -s) do_source=1 && shift ;;
        -i) do_install=1 && shift ;;
        -b) do_build=1 && shift ;;
        -e) do_export=1 && shift ;;
        -p) do_export_package=1 && shift ;;
        -r) do_create=1 && shift ;;
        -d) build_debug=1 && shift ;;
         *) build_targets+=("$1") && shift ;;
        -*) echo "Unknown option: $1" && exit 1 ;;
    esac
done

case "$(uname -m)" in
    x86_64)   arch=x64 ;;
esac

case "$OSTYPE" in
    linux*)   os=linux ;;
    msys*)    os=windows ;;
esac

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
git_root="$(git rev-parse --show-toplevel)"

if [ $os = "linux" ]; then
    export JAYSINCO_SOURCE_REPO=$git_root/src
elif [ $os = "windows" ]; then
    export JAYSINCO_SOURCE_REPO=$HOME/OneDrive/src
fi

conan_ref="jaysinco/stable"
conan_profile="$git_root/profiles/$arch-$os.profile"
build_type=Release

if [ $build_debug -eq 1 ]; then
    if [ $do_install -ne 1 -a $do_create -ne 1 -a $do_export_package -ne 1 ]; then
        echo "flag '-d' must be used in conan install/package context" && exit 1
    fi
    build_type=Debug
fi

function do_recipe() {
    local recipe_dir=$1
    local install_folder="out/$build_type"
    local common_args="\
        --install-folder=$install_folder \
        --profile=$conan_profile \
        --profile:build=$conan_profile \
        --settings=build_type=$build_type \
        "

    cd $recipe_dir

    if [ $do_clean -eq 1 -o $do_create -eq 1 ]; then
        rm -rf $recipe_dir/out $recipe_dir/src
    fi

    if [ $do_source -eq 1 -o $do_create -eq 1 ]; then
        conan source $recipe_dir
    fi

    if [ $do_install -eq 1 -o $do_create -eq 1 ]; then
        conan install $common_args \
            --build=never \
            $recipe_dir $conan_ref
    fi

    if [ $do_build -eq 1 -o $do_create -eq 1 ]; then
        conan build \
            --install-folder=$install_folder \
            $recipe_dir
    fi

    if [ $do_export -eq 1 ]; then
        conan export $recipe_dir $conan_ref
    fi

    if [ $do_export_package -eq 1 -o $do_create -eq 1 ]; then
        conan export-pkg $common_args \
            --force \
            $recipe_dir $conan_ref
    fi
}

for target in "${build_targets[@]}"; do
    target_dir=$git_root/recipes/$target
    if [ ! -d "$target_dir" ]; then
        echo "skip non-existent target '$target'" && continue
    fi
    do_recipe $target_dir
done