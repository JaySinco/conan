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


### 依赖项

```
pacman -S mingw-w64-x86_64-jq mingw-w64-x86_64-make mingw-w64-x86_64-gcc
cp /mingw64/bin/mingw32-make /mingw64/bin/make
```