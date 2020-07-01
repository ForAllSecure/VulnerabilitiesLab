FROM ubuntu:18.04 as builder
RUN apt-get update && \
	apt-get install -y \
		autoconf \
		automake \
		build-essential \
		libtool-bin \
		git \
        clang \
		zlib1g-dev

WORKDIR /build
COPY patch ./
ENV ASAN_OPTIONS=detect_leaks=0
RUN git clone https://github.com/tbeu/matio -b v1.5.15 && \
    cd matio && \
    patch -p1 < ../patch && \
    chmod +x fuzz/*.sh && \
	./autogen.sh && \
    ./fuzz/configure_libfuzzer.sh && \
    make && \
    ./fuzz/build_libfuzzer.sh && \
	make clean && \
    ./fuzz/configure_standalone.sh && \
    make && \
    ./fuzz/build_standalone.sh

FROM ubuntu:18.04
RUN apt-get update && apt-get install -y zlib1g

WORKDIR /mayhem
COPY --from=builder /build/matio/matio-libfuzzer /mayhem/matio-libfuzzer
COPY --from=builder /build/matio/matio-standalone /mayhem/matio-standalone
