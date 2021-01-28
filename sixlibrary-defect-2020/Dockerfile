FROM ubuntu as builder

RUN apt-get clean && apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install --fix-missing -y \
    clang cmake build-essential libc6-dbg git

WORKDIR /six
RUN git clone https://github.com/ngageoint/six-library . && git checkout b79e5da8a2b865e

COPY cmake.patch .
RUN git apply cmake.patch
RUN mkdir build && cd build && cmake -DENABLE_PYTHON=OFF --target=test_extract_xml .. && make -j4

FROM ubuntu

RUN apt-get update && apt-get install -y libc6-dbg

WORKDIR /six
COPY --from=builder /six/build/six/modules/c++/samples/test_* ./
