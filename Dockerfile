FROM ubuntu:noble

WORKDIR /tmp

# install tools and cross-compilers
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
	clang autoconf automake make libtool pkg-config gcc g++ \
	wget git bzip2 zip curl \
	libssl-dev vdr-dev zlib1g-dev libxml2-dev \
	binutils-arm-linux-gnueabihf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
	binutils-mipsel-linux-gnu gcc-multilib-mipsel-linux-gnu g++-multilib-mipsel-linux-gnu && \
	rm -rf /var/apt/lists/*

# install libraries for all architectures
COPY build_*.sh .
RUN ./build_libraries.sh
