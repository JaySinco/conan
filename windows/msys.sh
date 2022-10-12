#!/bin/bash

if [ "$MSYSTEM" != "MSYS" ]; then
	echo "Subsystems Not MSYS!"
	exit 1
fi

pacman_need_sync=0
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

function modify_mirror() {
	if [ "$(head -n 1 $1)" != "$2" ]; then
		echo "modify $1"
		sed -i "1s|^|$2\n|" $1
		pacman_need_sync=1
	fi
}

modify_mirror /etc/pacman.d/mirrorlist.mingw32 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/i686'
modify_mirror /etc/pacman.d/mirrorlist.mingw64 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/x86_64'
modify_mirror /etc/pacman.d/mirrorlist.ucrt64  'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/ucrt64'
modify_mirror /etc/pacman.d/mirrorlist.clang64 'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/clang64'
modify_mirror /etc/pacman.d/mirrorlist.msys    'Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/$arch'

if [ $pacman_need_sync -eq 1 ]; then pacman --noconfirm -Sy; fi

if [ ! -f "/etc/profile.d/git-prompt.sh" ]; then
	echo "copy git-prompt.sh"
	cp $script_dir/git-prompt.sh /etc/profile.d/
fi

s1='shopt -q login_shell || . /etc/profile.d/git-prompt.sh'
if ! grep -q "$s1" ~/.bashrc; then
	echo "change ~/.bashrc for git prompt"
	echo "$s1" >> ~/.bashrc
fi

if [ ! -f ~/.ssh/id_rsa ]; then
	echo "copy ssh key"
	mkdir -p ~/.ssh
	cp $USERPROFILE/OneDrive/src/id_rsa ~/.ssh
	cp $USERPROFILE/OneDrive/src/id_rsa.pub ~/.ssh
fi

if [ ! -f "/usr/bin/gcc" ]; then pacman --noconfirm -S base-devel binutils gcc; fi
if [ ! -f "/mingw64/bin/ninja" ]; then pacman --noconfirm -S mingw-w64-x86_64-ninja; fi
if [ ! -f "/mingw64/bin/cmake" ]; then pacman --noconfirm -S mingw-w64-x86_64-cmake; fi
if [ ! -f "/mingw64/bin/jq" ]; then pacman --noconfirm -S mingw-w64-x86_64-jq; fi
