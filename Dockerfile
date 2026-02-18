FROM ubuntu:noble

WORKDIR /tmp

# install tools and cross-compilers
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
	autoconf automake make libtool pkg-config gcc g++ \
	wget git bzip2 zip curl cmake liblzma-dev \
	libssl-dev vdr-dev zlib1g-dev libxml2-dev libatomic1-mips-cross \
	binutils-arm-linux-gnueabihf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
	binutils-mipsel-linux-gnu gcc-multilib-mipsel-linux-gnu g++-multilib-mipsel-linux-gnu && \
	rm -rf /var/apt/lists/*

# install semver so we can figure out the next version when building binaries
RUN sh -c 'curl -fsSL https://deb.nodesource.com/setup_22.x | bash -' && \
	apt-get -y install nodejs && \
	npm install -g semver && \
	rm -rf /var/apt/lists/*

# Needed for MIPS r1
RUN mkdir -p /opt/clang && cd /opt/clang && \
	curl -L -s https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/LLVM-21.1.8-Linux-X64.tar.xz  |  tar xJf - --strip-components=1

ENV PATH="$PATH:/opt/clang/bin"
# install libraries for all architectures
COPY build_*.sh .

RUN ./build_libraries.sh
