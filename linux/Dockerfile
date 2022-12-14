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
# apt-get install -y openssh-server
# systemctl status ssh

# font
# -----------------
# Hack Nerd Font 10
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

# qt5 deps
# -----------------
RUN apt-get update -y \
    && apt-get install -y wget software-properties-common \
    && apt-get build-dep -y qt5-default

# gcc
# -----------------
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update -y \
    && apt-get install -y gcc-11 g++-11 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-11

# clang
# -----------------
RUN wget -q -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository 'deb https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/focal/ llvm-toolchain-focal-15 main' \
    && apt-get update -y \
    && apt-get install -y clangd-15 clang-format-15 clang-tidy-15 lldb-15 libclang-15-dev \
    && ln -fs /usr/bin/clangd-15 /usr/bin/clangd \
    && ln -fs /usr/bin/clang-format-15 /usr/bin/clang-format \
    && ln -fs /usr/bin/clang-tidy-15 /usr/bin/clang-tidy \
    && ln -fs /usr/bin/lldb-15 /usr/bin/lldb \
    && ln -fs /usr/bin/lldb-vscode-15 /usr/bin/lldb-vscode \
    && ln -fs /usr/bin/llvm-config-15 /usr/bin/llvm-config \
    && mkdir -p /usr/lib/lib/python3.8/site-packages/lldb \
    && ln -s /usr/lib/llvm-15/lib/python3.8/site-packages/lldb/* /usr/lib/lib/python3.8/site-packages/lldb/

# common utils
# -----------------
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get update -y \
    && apt-get install -y gdb zip git git-lfs git-gui ninja-build \
        nodejs ttf-wqy-microhei

# switch user
# -----------------
RUN apt-get update -y \
    && apt-get install -y sudo \
    && useradd -u 1000 -m jaysinco \
    && usermod -aG sudo jaysinco \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER jaysinco

COPY src/nvim-v0.7.2-linux-x86_64.tar.gz \
     src/code_1.71.2-1663191218_amd64.deb \
     src/font-hack.zip \
     src/res/get-pip.py \
     /tmp/

# install
# -----------------
RUN sudo apt-get update -y \
    && sudo apt-get install -y xclip jq ripgrep flex bison \
    && sudo apt-get install -y libnspr4 libnss3 libsecret-1-0 xdg-utils \
    && sudo npm install -g typescript-language-server typescript pyright \
    && sudo ln -fs /usr/bin/python3 /usr/bin/python \
    && python /tmp/get-pip.py \
    && python -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && python -m pip install conan==1.52 debugpy

# copy files
# -----------------
RUN cd /tmp \
    && sudo tar zxf nvim-v0.7.2-linux-x86_64.tar.gz --directory=/usr --strip-components=1 \
    && sudo dpkg -i code_1.71.2-1663191218_amd64.deb \
    && mkdir -p /home/jaysinco/.local/share \
    && sudo unzip font-hack.zip -d /home/jaysinco/.local/share/fonts \
    && sudo rm -rf /tmp/*

# config
# -----------------
ENV XDG_RUNTIME_DIR=/home/jaysinco/xdg-runtime-root \
    NO_AT_BRIDGE=1 \
    PATH="/home/jaysinco/.local/bin:${PATH}"

COPY git-prompt.sh /etc/profile.d

RUN mkdir -p $XDG_RUNTIME_DIR \
    && chmod 700 $XDG_RUNTIME_DIR \
    && git config --global user.name jaysinco \
    && git config --global user.email jaysinco@163.com \
    && echo "shopt -q login_shell || . /etc/profile.d/git-prompt.sh" >> /home/jaysinco/.bashrc

WORKDIR /home/jaysinco
ENTRYPOINT ["/bin/bash"]
