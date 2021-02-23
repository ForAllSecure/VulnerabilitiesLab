FROM ubuntu:18.04

RUN apt-get update && apt-get install -y build-essential libc6-dbg git

WORKDIR /build

RUN git clone https://github.com/TooDumbForAName/ncsa-httpd && \
    cd ncsa-httpd && \
    git checkout 1.5c

COPY ./src .

RUN cd ncsa-httpd/cgi-src && \
    git apply ../../fix.patch && \
    make phf

RUN gcc envfuzz.c -o envfuzz.so -shared -fPIC -ldl -g
