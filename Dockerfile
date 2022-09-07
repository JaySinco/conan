FROM ubuntu:20.04

# docker
# -----------------
# apt-get install -y docker.io
# usermod -aG docker $USER
# printf '{"registry-mirrors":["https://docker.mirrors.ustc.edu.cn/"]}' > /etc/docker/daemon.json
# systemctl daemon-reload && systemctl restart docker

# ssh
# -----------------
# chmod 700 .ssh
# chmod 600 .ssh/id_rsa
# chmod 644 .ssh/id_rsa.pub
# ssh-add

# font
# -----------------
# FiraMono Nerd Font Medium 11
# mv *.ttf ~/.local/share/fonts
# fc-cache -fv

# locale
# -----------------
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y ca-certificates \
    && cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    && printf 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse\n' > /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get install -y apt-utils tzdata language-pack-zh-hans \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# cmake
# -----------------
COPY src/cmake-3.23.1.tar.gz /tmp/

RUN apt-get update -y \
    && apt-get install -y build-essential curl libssl-dev \
    && cd /tmp \
    && tar zxvf cmake-3.23.1.tar.gz \
    && cd /tmp/cmake-3.23.1 \
    && ./bootstrap --prefix=/usr/local --parallel=`nproc` \
    && make -j`nproc` \
    && make install \
    && rm -rf /tmp/cmake-3.23.1 /tmp/cmake-3.23.1.tar.gz

# clang
# -----------------
RUN apt-get update -y \
    && apt-get install -y wget software-properties-common \
    && wget -q -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository 'deb https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/focal/ llvm-toolchain-focal-13 main' \
    && apt-get update -y \
    && apt-get install -y clang-13 lldb-13 lld-13 clangd-13 clang-format-13 libc++-13-dev libc++abi-13-dev \
    && ln -s /usr/bin/clang-13 /usr/bin/clang \
    && ln -s /usr/bin/clang++-13 /usr/bin/clang++ \
    && ln -s /usr/bin/ld.lld-13 /usr/bin/ld.lld \
    && ln -s /usr/bin/clangd-13 /usr/bin/clangd \
    && ln -s /usr/bin/clang-format-13 /usr/bin/clang-format

# build dep
# -----------------
RUN apt-get update -y \
    && apt-get build-dep -y qt5-default \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y sudo gdb git git-lfs git-gui python3 python3-pip \
    	nodejs zip tcl tk-dev

# user
# -----------------
RUN useradd -u 1000 -m jaysinco \
    && usermod -aG sudo jaysinco \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# copy files
# -----------------
COPY src/nvim-0.7.0-linux-x86_64.tar.gz \
     src/lua-language-server-3.2.5-linux-x64.tar.gz \
     /tmp/
     
RUN cd /tmp \
    && tar zxvf nvim-0.7.0-linux-x86_64.tar.gz --directory=/usr --strip-components=1 \
    && mkdir -p /home/jaysinco/apps/lua-language-server \
    && tar zxvf lua-language-server-3.2.5-linux-x64.tar.gz --directory=/home/jaysinco/apps/lua-language-server \
    && rm -f *.tar.gz
    
# install
# -----------------
RUN apt-get update -y \
    && apt-get install -y xclip jq ripgrep \
    && npm install -g typescript-language-server typescript \
    && pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip3 install conan

# config
# -----------------
ENV PATH="/home/jaysinco/apps/lua-language-server/bin:/home/jaysinco/.local/bin:${PATH}"

RUN git config --global user.name jaysinco \
    && git config --global user.email jaysinco@163.com \
    && git config --global --add safe.directory /home/jaysinco/workspace \
    && git config --global --add safe.directory /home/jaysinco/.config/nvim

# entry
# -----------------
USER jaysinco
WORKDIR /home/jaysinco/workspace
ENTRYPOINT ["/bin/bash"]

