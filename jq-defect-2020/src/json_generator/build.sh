#!/bin/bash

# Generate cpp files from protobuf specifications
protoc --cpp_out=. json.proto

# standalone JSON generator program
clang++ json_generator.cpp json_writer.cpp json.pb.cc \
    /src/libprotobuf-mutator/src/libfuzzer/libfuzzer_macro.cc \
    /src/libprotobuf-mutator/src/libfuzzer/libfuzzer_mutator.cc \
    -g -fsanitize=fuzzer \
    -I /usr/local/include/libprotobuf-mutator/ \
    -lprotobuf -pthread -lprotobuf-mutator \
    -o json_generator

test -f json_generator && echo "[*] Build succeeded" || exit 1
