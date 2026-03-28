FROM ubuntu:25.04

WORKDIR /tmp

# install tools and cross-compilers
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
	autoconf automake make libtool pkg-config gcc g++ \
	wget git bzip2 zip curl cmake liblzma-dev xz-utils \
	libssl-dev vdr-dev zlib1g-dev libxml2-dev \
	binutils-arm-linux-gnueabihf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
	flex bison texinfo gawk \
	linux-headers-generic linux-libc-dev-mipsel-cross && \
	rm -rf /var/apt/lists/*

# install semver so we can figure out the next version when building binaries
RUN sh -c 'curl -fsSL https://deb.nodesource.com/setup_22.x | bash -' && \
	apt-get -y install nodejs && \
	npm install -g semver && \
	rm -rf /var/apt/lists/*

# install libraries for all architectures
COPY build_*.sh .

RUN ./build_mips.sh
ENV PATH=$PATH:/opt/mipsel/bin
RUN ./build_libraries.sh
