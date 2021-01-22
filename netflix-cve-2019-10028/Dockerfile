FROM debian:buster-slim as builder

# Install Essentials
RUN apt-get update && \
    apt-get install -y \
    libcurl4-openssl-dev zlib1g-dev libssl-dev build-essential git \
    gdb

# Get the current dial-reference repo
WORKDIR /build
RUN git clone https://github.com/Netflix/dial-reference.git . && \
    # Check out version before flaw was fixed
    git checkout bfde1461449f6c0dfde3d2a826b97cace325cc75 && \
    git checkout HEAD^ && \
    make && \
    cp server/libnfCallbacks.so /lib/x86_64-linux-gnu
COPY http.dict .

FROM debian:buster-slim
RUN apt-get update && apt-get install -y libc6-dbg 

WORKDIR /fuzz/server

COPY --from=builder /build/server/dialserver .
COPY --from=builder /build/server/libnfCallbacks.so /lib/x86_64-linux-gnu
COPY http.dict .
EXPOSE 56790/tcp
CMD ["/fuzz/server/dialserver"]
