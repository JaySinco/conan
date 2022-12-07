#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source_repo=$git_root/../dev-setup/linux/src

# git config
# -----------------
git config --global core.autocrlf input
git config --global core.safecrlf true
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
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
fi

