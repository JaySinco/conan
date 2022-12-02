#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source_repo=$git_root/../dev-setup/linux/src
nvim_version="0.7.2"
nvim_data_dir=$HOME/.local/share/nvim

# copy file
# -----------------
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "copy ~/.ssh key"
    mkdir -p ~/.ssh
    cp $source_repo/res/id_rsa ~/.ssh
    cp $source_repo/res/id_rsa.pub ~/.ssh
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
fi

if [ ! -d $nvim_data_dir/site ]; then
    echo "copy nvim data"
    mkdir -p $nvim_data_dir
    unzip -q $source_repo/nvim-data-site-v$nvim_version-linux-x86_64.zip -d $nvim_data_dir
fi
