#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
program_files_dir=$USERPROFILE/ProgramFiles
source_repo=$USERPROFILE/OneDrive/src

# setup msys
# -----------------
MSYSTEM=MSYS /usr/bin/bash --login $script_dir/set-msys.sh

# git config
# -----------------
git config --global core.autocrlf true
git config --global core.safecrlf false
git config --global core.longpaths true
git config --global core.quotepath false
git config --global i18n.filesEncoding utf-8
git config --global pull.rebase false
git config --global fetch.prune true

# copy file
# -----------------
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "copy ~/.ssh key"
    mkdir -p ~/.ssh
    cp $source_repo/res/id_rsa ~/.ssh
    cp $source_repo/res/id_rsa.pub ~/.ssh
fi

if [ ! -f $USERPROFILE/.ssh/id_rsa ]; then
    echo 'copy $USERPROFILE/.ssh key'
    mkdir -p $USERPROFILE/.ssh
    cp $source_repo/res/id_rsa $USERPROFILE/.ssh
    cp $source_repo/res/id_rsa.pub $USERPROFILE/.ssh
fi

if [ ! -d $program_files_dir/nvim-win64 ]; then
    echo "copy nvim"
    mkdir -p $program_files_dir
    unzip -q $source_repo/nvim-v$nvim_version-windows-x86_64.zip -d $program_files_dir
fi

if [[ ! $(type -P "conan") ]]; then
    echo "install conan"
    pip3 install conan -i https://pypi.tuna.tsinghua.edu.cn/simple
fi

if [[ ! $(type -P "pyright") ]]; then
    echo "install pyright"
    npm install -g pyright
fi

if [[ ! $(type -P "typescript-language-server") ]]; then
    echo "install typescript-language-server"
    npm install -g typescript-language-server typescript
fi