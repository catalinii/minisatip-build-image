FROM jalle19/centos7-stlinux24:latest

FROM ubuntu:lunar
COPY --from=0 /opt /opt
ARG TOKEN2

# install ARM cross compiler
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -f -y clang wget git binutils-arm-linux-gnueabihf autoconf automake make libtool gcc-multilib-mipsel-linux-gnu gcc-arm-linux-gnueabihf gcc bzip2 libssl-dev pkg-config g++ vdr-dev zlib1g-dev libxml2-dev curl vim zip curl

# install MIPS arch: openwrt and enigma based
RUN mkdir -p /opt/zig && \
	cd /opt/zig && \
	curl -L -s https://ziglang.org/download/0.13.0/zig-0.13.0.tar.xz  |  tar xJf - --strip-components=1

# install DVBCSA for ARM ... the other archs have it already in the toolchain
COPY build_libraries.sh .
RUN ./build_libraries.sh

RUN --mount=type=secret,id=TOKEN2 \
    cp /run/secrets/TOKEN2 /etc/coverity && \
	mkdir /cov-analysis-linux64 && \
	wget https://scan.coverity.com/download/cxx/linux64 --post-data "token=$(cat /etc/coverity)&project=minisatip2" -O cov-analysis-linux64.tar.gz && \
	tar xzf cov-analysis-linux64.tar.gz --strip 1 -C /cov-analysis-linux64

ENV PATH="$PATH:/opt/STM/STLinux-2.4/devkit/sh4/bin:/opt/zig:/cov-analysis-linux64/bin"
