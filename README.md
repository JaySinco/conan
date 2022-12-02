# Windows

## MSYS2

### 镜像

编辑 `/etc/pacman.d/mirrorlist.mingw32` ，在文件开头添加：
```
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/i686
```

编辑 `/etc/pacman.d/mirrorlist.mingw64` ，在文件开头添加：
```
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/x86_64
```

编辑 `/etc/pacman.d/mirrorlist.ucrt64` ，在文件开头添加：
```
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/ucrt64
```

编辑 `/etc/pacman.d/mirrorlist.clang64` ，在文件开头添加：
```
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/clang64
```

编辑 `/etc/pacman.d/mirrorlist.msys` ，在文件开头添加：
```
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/$arch
```

然后执行 `pacman -Sy` 刷新软件包数据即可

### Git提示符

编辑 `~/.bashrc` ，在文件末尾添加：
```shell
shopt -q login_shell || . /etc/profile.d/git-prompt.sh
```

## 安装软件
- Visual Studio
- VSCode
- LLVM
- Nodejs
- Python
- Windows Terminal
- MSYS2
- PortableGit*

<font size=2>注：*代表需要加PATH环境变量<font>
