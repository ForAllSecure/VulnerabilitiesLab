FROM ubuntu:18.04 AS builder

RUN export DEBIAN_FRONTEND="noninteractive" && \
    apt-get update -qq && \
    apt-get install -y build-essential autotools-dev automake autoconf libtool git libssl-dev

WORKDIR /sthttpd
RUN git clone https://github.com/blueness/sthttpd . && \
    git checkout c0dc63a49d8605649f1d8e4a96c9b468b0bff660 && \
    git checkout HEAD^

RUN ./autogen.sh && ./configure && make

FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y libssl1.1 libc6-dbg && \
    apt-get clean all

WORKDIR /fuzz
COPY --from=builder /sthttpd/src/thttpd .
