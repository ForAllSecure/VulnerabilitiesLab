#!/bin/bash
tar xf afl-2.52b.tgz
cd afl-2.52b
make
make -C llvm_mode LLVM_CONFIG=llvm-config-6.0 CC=clang-6.0
