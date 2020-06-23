FROM debian:buster-slim

RUN apt-get update && apt-get install -y build-essential bison flex libssl-dev bc clang-6.0 wget

WORKDIR /mayhem
RUN wget https://lcamtuf.coredump.cx/afl/releases/afl-2.52b.tgz && \
    wget https://github.com/u-boot/u-boot/archive/v2019.07-rc4.tar.gz
COPY src .
RUN ./build-afl.sh
RUN ./build-u-boot.sh
