#!/bin/bash

echo "[*] Generating protobuf code"
protoc --cpp_out=. json.proto

echo "[*] Building object files"
clang++ json_writer.cpp -g -c
clang++ json.pb.cc -g -c
clang++ harness_jq_parse.cpp -g -c \
        -I /usr/local/include/libprotobuf-mutator
clang++ /src/libprotobuf-mutator/src/libfuzzer/libfuzzer_macro.cc -g -c \
        -I /usr/local/include/libprotobuf-mutator
clang++ /src/libprotobuf-mutator/src/libfuzzer/libfuzzer_mutator.cc -g -c \
        -I /usr/local/include/libprotobuf-mutator

echo "[*] Linking executables"
clang++ harness_jq_parse.o json_writer.o json.pb.o \
        libfuzzer_macro.o libfuzzer_mutator.o \
        -fsanitize=fuzzer \
        /usr/local/lib/libjq.a \
        -lonig -lprotobuf -lprotobuf-mutator \
        -o fuzzer_json_parse

test -f fuzzer_json_parse && echo "[*] Build succeeded" || exit 1
