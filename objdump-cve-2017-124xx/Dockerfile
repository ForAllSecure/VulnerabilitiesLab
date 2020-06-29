FROM ubuntu:18.04

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wget build-essential gcc-multilib g++-multilib && \
    apt-get install -y gcc-i686-linux-gnu linux-libc-dev:i386 libc6-dbg:i386

RUN wget https://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2 && \
    tar xvf binutils-2.24.tar.bz2

WORKDIR /binutils-2.24
RUN ./configure --host=i686-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" && \
    find . -type f -exec sed -i 's/-Werror//g' {} \; && \
    make && make install
