FROM debian:buster-slim AS builder
LABEL maintainer="guido@guidovranken.com"

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    curl \
    gawk \
    bison \
    python3

RUN mkdir -p /src
RUN mkdir -p /build
WORKDIR /src

RUN curl -O https://ftp.gnu.org/gnu/libc/glibc-2.31.tar.bz2 && \
    tar jxf glibc-2.31.tar.bz2
RUN mkdir /src/glibc-2.31/build

COPY src/* /build/
RUN /build/build.sh

FROM debian:buster-slim
WORKDIR /fuzz
COPY --from=builder /build/libm-tester .
