#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
program_files_dir=$USERPROFILE/ProgramFiles
source_repo=$USERPROFILE/OneDrive/src

# setup msys
# -----------------
MSYSTEM=MSYS /usr/bin/bash --login $script_dir/set-msys.sh

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
    unzip -q $source_repo/nvim-0.7.2-windows-x86_64.zip -d $program_files_dir
fi

nvim_data_dir=$LOCALAPPDATA/nvim-data
if [ ! -d $nvim_data_dir/site ]; then
    echo "copy nvim data"
    mkdir -p $nvim_data_dir
    unzip -q $source_repo/nvim-data-site-v2022.09.24-$os.zip -d $nvim_data_dir
fi

if [ ! -d $program_files_dir/lua-language-server ]; then
    echo "copy lua-language-server"
    mkdir -p $program_files_dir/lua-language-server
    unzip -q $source_repo/lua-language-server-3.2.4-win32-x64.zip -d $program_files_dir/lua-language-server
fi