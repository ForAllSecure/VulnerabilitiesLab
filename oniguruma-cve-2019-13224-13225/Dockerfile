FROM ubuntu:18.04

# Download necessary packages.
RUN apt-get update && apt-get install -y \
    git clang build-essential autoconf libtool-bin

WORKDIR /oniguruma
RUN git clone --no-checkout https://github.com/kkos/oniguruma . && \
    git checkout -q v6.9.3

COPY src .

# Build all targets to /oniguruma/fuzzers
RUN ./build_fuzzers.sh
