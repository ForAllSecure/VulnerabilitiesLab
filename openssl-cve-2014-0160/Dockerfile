# Copyright 2020 ForAllSecure Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################


FROM debian:buster-slim as builder
LABEL maintainer="support@forallsecure.com"

RUN apt-get update && \
        apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        clang++-7 \
        curl \
        git \
        libc6-dbg \
        libfuzzer-7-dev \
        libunwind8-dev && \
        rm -rf /var/lib/apt-lists/* && \
        update-alternatives --install  /usr/bin/clang clang /usr/bin/clang-7 10 && \
        update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-7 10

# Build the handshake openssl target
WORKDIR /build
COPY src/build.sh build.sh
RUN ./build.sh

# Copy in the corpus in case you want to try locally
WORKDIR /corpus
COPY corpus/ corpus/


########################################################################
# Optimization: Second stage for smaller push
#
# After build, you don't need many of the dependencies. See Tip 11 at:
# https://www.docker.com/blog/intro-guide-to-dockerfile-best-practices/
########################################################################
FROM debian:buster-slim
LABEL maintainer="support@forallsecure.com"
WORKDIR /build
COPY --from=builder /build/handshake-fuzzer /build/handshake-fuzzer
COPY --from=builder /build/server.key /build/server.key
COPY --from=builder /build/server.pem /build/server.pem
COPY corpus /corpus

# Convenience function: start the fuzzer with docker run
CMD ./handshake-fuzzer /corpus
