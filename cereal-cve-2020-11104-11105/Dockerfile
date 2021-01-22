FROM debian:buster-slim
LABEL maintainer="guido@guidovranken.com"

RUN apt-get update --allow-releaseinfo-change && \
        apt-get install --no-install-recommends -y build-essential \
        ca-certificates git  clang curl git gcc-multilib \
        g++-multilib libc6-dbg

WORKDIR /src


# Get the latest libFuzzer
RUN git clone https://github.com/llvm/llvm-project && \
    mv llvm-project/compiler-rt/lib/fuzzer Fuzzer && \
    rm -rf llvm-project
    
RUN cp -R Fuzzer/ Fuzzer32/

# Build 64 bit libFuzzer
RUN cd /src/Fuzzer && ./build.sh

# Build 32 bit libFuzzer
RUN sed -i "s/\$CXX/\$CXX -m32/g" /src/Fuzzer32/build.sh
RUN cd /src/Fuzzer32 && ./build.sh

# Get my custom fuzzing headers
RUN git clone --depth 1 https://github.com/guidovranken/fuzzing-headers.git
RUN cd /src/fuzzing-headers && ./install.sh

# Download the vulnerable cereal version
RUN curl -o cereal-1.3.0.tar.gz https://codeload.github.com/USCiLab/cereal/tar.gz/v1.3.0 && \
        tar zxf cereal-1.3.0.tar.gz && \
        ln -s cereal-1.3.0 cereal

# Copy in cereal fuzzing harnesses
COPY src/ /src/cereal/fuzzer/
COPY poc/ /src/poc

# Set the build directory
WORKDIR /src/cereal/fuzzer

# Compile the fuzzing harnesses
RUN     CC=clang \
       CXX=clang++ \
       CEREAL_INCLUDE_PATH="/src/cereal/include" \
       LIBFUZZER64_PATH="/src/Fuzzer/libFuzzer.a" \
       LIBFUZZER32_PATH="/src/Fuzzer32/libFuzzer.a" \
       CXXFLAGS="-fsanitize=address,undefined,fuzzer-no-link -g -O1" make
