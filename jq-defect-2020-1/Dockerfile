FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    gcc git autoconf libtool make clang libc6-dbg \
    ninja-build liblzma-dev libz-dev pkg-config cmake binutils wget tar  \
    nasm curl \
    libtool-bin gettext \
    gdb valgrind vim

WORKDIR /src

# Build libprotobuf
WORKDIR /src
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protobuf-all-3.9.1.tar.gz
RUN tar -xf protobuf-all-3.9.1.tar.gz
WORKDIR /src/protobuf-3.9.1
RUN ./configure && \
    make -j8 && \
    make install
RUN ldconfig

# Build libprotobuf-mutator
WORKDIR /src
RUN git clone https://github.com/google/libprotobuf-mutator
WORKDIR /src/libprotobuf-mutator
RUN mkdir build && \
    cd build && \
    cmake .. -GNinja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Debug && \
    ninja && \
    ninja install

# checkout and build the desired version of jq
WORKDIR /src
ARG VERSION="5b9e63e4af339bc5867603f14441b4b4cbb9e175"
RUN git clone --no-checkout https://github.com/stedolan/jq
WORKDIR /src/jq
RUN git checkout -q $VERSION
RUN git submodule update --init && \
    autoreconf -fi && \
    ./configure CC=clang CFLAGS="-fsanitize=fuzzer-no-link -fsanitize=address" \
       --host=x86_64-linux-gnu --with-oniguruma=builtin --disable-docs && \
    make -j8 && \
    make install && \
    ldconfig

# Build harnesses
WORKDIR /src/harness
COPY ./src/ /src/harness
RUN ./build.sh
COPY ./mayhem/jq_parse_fuzzer/corpus /src/harness/corpus/
COPY ./poc /src/harness/poc/

RUN update-alternatives --install /usr/bin/llvm-symbolizer llvm-symbolizer /usr/bin/llvm-symbolizer-6.0 100

# Convenience helper to run the fuzzer
CMD /src/harness/fuzzer_jq_pair -detect_leaks=0 -close_fd_mask=3 corpus
