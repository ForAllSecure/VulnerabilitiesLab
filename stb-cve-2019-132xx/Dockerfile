FROM ubuntu:18.04 as builder

RUN apt-get update && \
	apt-get install -y \
		build-essential \
		clang \
		git

WORKDIR /build
COPY src/patch .
ENV ASAN_OPTIONS=detect_leaks=0

RUN git clone https://github.com/nothings/stb.git && \
    cd stb && \
    git checkout c72a95d766b8cbf5514e68d3ddbf6437ac9425b1 && \
    patch -p1 < ../patch && \
    chmod +x fuzz/*.sh && \
    ./fuzz/build_libfuzzer.sh && \
    ./fuzz/build_standalone.sh

FROM ubuntu:18.04

WORKDIR /mayhem
COPY --from=builder /build/stb/stb-vorbis-libfuzzer /mayhem/stb-vorbis-libfuzzer
COPY --from=builder /build/stb/stb-vorbis-standalone /mayhem/stb-vorbis-standalone
