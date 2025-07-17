FROM ubuntu:noble

WORKDIR /tmp

# install ARM cross compiler
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -f -y clang libclang-cpp18 wget git binutils-arm-linux-gnueabihf autoconf automake make libtool gcc-multilib-mipsel-linux-gnu gcc-arm-linux-gnueabihf g++-multilib-mipsel-linux-gnu g++-arm-linux-gnueabihf gcc bzip2 libssl-dev pkg-config g++ vdr-dev zlib1g-dev libxml2-dev curl vim zip curl

# install MIPS arch: openwrt and enigma based
RUN mkdir -p /opt/zig && \
	cd /opt/zig && \
	curl -L -s https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz  |  tar xJf - --strip-components=1

# install libraries for all architectures
COPY build_*.sh .
RUN ./build_libraries.sh

ENV PATH="$PATH:/opt/zig"
