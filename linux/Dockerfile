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

# clangd
# -----------------
RUN wget -q -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository 'deb https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/focal/ llvm-toolchain-focal-15 main' \
    && apt-get update -y \
    && apt-get install -y clangd-15 clang-format-15 \
    && ln -s /usr/bin/clangd-15 /usr/bin/clangd \
    && ln -s /usr/bin/clang-format-15 /usr/bin/clang-format

# common utils
# -----------------
RUN apt-get update -y \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y gdb zip git git-lfs git-gui ninja-build \
        python3 python3-pip nodejs ttf-wqy-microhei

# switch user
# -----------------
RUN apt-get update -y \
    && apt-get install -y sudo \
    && useradd -u 1000 -m jaysinco \
    && usermod -aG sudo jaysinco \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER jaysinco

# install
# -----------------
RUN sudo apt-get update -y \
    && sudo apt-get install -y xclip jq ripgrep \
    && sudo apt-get install -y libnspr4 libnss3 libsecret-1-0 xdg-utils \
    && sudo npm install -g typescript-language-server typescript pyright \
    && pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip3 install --no-warn-script-location conan

# copy files
# -----------------
COPY src/nvim-0.7.0-linux-x86_64.tar.gz \
     src/lua-language-server-3.2.5-linux-x64.tar.gz \
     src/code_1.71.2-1663191218_amd64.deb \
     src/FiraMono.zip \
     /tmp/

RUN cd /tmp \
    && sudo tar zxf nvim-0.7.0-linux-x86_64.tar.gz --directory=/usr --strip-components=1 \
    && mkdir -p /home/jaysinco/apps/lua-language-server \
    && sudo tar zxf lua-language-server-3.2.5-linux-x64.tar.gz --directory=/home/jaysinco/apps/lua-language-server \
    && sudo dpkg -i code_1.71.2-1663191218_amd64.deb \
    && mkdir -p /home/jaysinco/.local/share \
    && sudo unzip FiraMono.zip -d /home/jaysinco/.local/share/fonts \
    && sudo rm -rf /tmp/*

# config
# -----------------
ENV XDG_RUNTIME_DIR=/home/jaysinco/xdg-runtime-root \
    NO_AT_BRIDGE=1 \
    PATH="/home/jaysinco/apps/lua-language-server/bin:/home/jaysinco/.local/bin:${PATH}" \
    LD_LIBRARY_PATH="/home/jaysinco/.conan/data/torch/1.8.2/jaysinco/stable/package/4db1be536558d833e52e862fd84d64d75c2b3656/lib"

COPY git-prompt.sh /etc/profile.d

RUN mkdir -p $XDG_RUNTIME_DIR \
    && git config --global user.name jaysinco \
    && git config --global user.email jaysinco@163.com \
    && echo "shopt -q login_shell || . /etc/profile.d/git-prompt.sh" >> /home/jaysinco/.bashrc

WORKDIR /home/jaysinco
ENTRYPOINT ["/bin/bash"]
