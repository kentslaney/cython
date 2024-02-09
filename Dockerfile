FROM archlinux
RUN pacman-key --init
RUN pacman -Sy --noconfirm archlinux-keyring
RUN pacman -S --noconfirm git base-devel
RUN useradd -m docker
RUN usermod -p '!' docker
RUN echo 'docker ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker
WORKDIR /home/docker
RUN git clone https://aur.archlinux.org/yay.git
WORKDIR /home/docker/yay
RUN makepkg -si --noconfirm
RUN yay -Sy --noconfirm python-dbg
RUN git clone --recurse-submodules -j8 https://github.com/boostorg/boost.git /home/docker/boost
WORKDIR /home/docker/boost
RUN ./bootstrap.sh
RUN sudo ./b2 install
RUN sudo pacman -S --noconfirm xz source-highlight readline
RUN git clone https://sourceware.org/git/binutils-gdb.git /home/docker/gdb
WORKDIR /home/docker/gdb
RUN curl -o maxlen.patch https://raw.githubusercontent.com/ali1234/rpi-toolchain/2ea7ffdae865ce54f53ed69ccf5e7d31d90dfb72/patches/gdb/8.2.1/0001-DouglasRoyds-workaround-for-deeply-nested-confdir3.patch
RUN sed -i 's!gdb/gnu!gnu!g' maxlen.patch
RUN git apply maxlen.patch
RUN ./configure --with-system-readline --with-python="`which python-dbg`"
RUN make
RUN sudo make install
RUN git clone https://github.com/unicode-org/icu /home/docker/icu
WORKDIR /home/docker/icu/icu4c/source
RUN ./configure
RUN make -i
RUN sudo make install -i
ENV LD_LIBRARY_PATH=/usr/local/lib
RUN while gdb -h 2>&1 | grep libicu &>/dev/null; do gdb -h 2>&1 | sed 's!.*\(\(libicu\w\+.so\).\w\+\).*!/usr/local/lib/\2 /usr/local/lib/\1!' | xargs sudo ln -s; done
RUN git clone https://github.com/kentslaney/cython.git /home/docker/cython
WORKDIR /home/docker/cython
RUN git checkout gdb-segfault
RUN python-dbg -m pip install virtualenv
RUN python-dbg -m virtualenv venv
RUN venv/bin/pip install -e .
RUN echo "source /home/docker/cython/venv/bin/activate" >> /home/docker/.bashrc
CMD CFLAGS="-O0 -ggdb" python-dbg runtests.py -vv Debugger --backends=c,cpp
