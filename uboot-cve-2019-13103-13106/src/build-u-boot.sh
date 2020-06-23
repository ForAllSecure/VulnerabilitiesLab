#!/bin/bash
DIR=u-boot-2019.07-rc4
SRCTAR="v2019.07-rc4.tar.gz"
tar -xf "$SRCTAR"
cd "$DIR"
export NO_SDL=1
patch -p1 < ../afl.patch
export AFL_CC=clang-6.0
export AFL_PATH="$PWD/../afl-2.52b/"
make sandbox_defconfig
make CC=$AFL_PATH/afl-clang-fast \
     CXX=$AFL_PATH/afl-clang-fast++ \
     EXTRA_CFLAGS="-O3 -g" \
     EXTRA_LDFLAGS="-O3 -g" \
     V=1
