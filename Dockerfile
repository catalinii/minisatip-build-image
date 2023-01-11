FROM jalle19/centos7-stlinux24:latest

FROM ubuntu:22.04
COPY --from=0 /opt /opt
ARG TOKEN2

# install ARM cross compiler
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -f -y wget git binutils-arm-linux-gnueabihf autoconf automake make libtool gcc-arm-linux-gnueabihf gcc bzip2 dvb-apps libssl-dev pkg-config g++ vdr-dev zlib1g-dev libxml2-dev curl vim zip libc6-i386 lib32z1 curl libssl-dev

# install MIPS arch: openwrt and enigma based
RUN cd /opt && \
	wget https://minisatip.org/tmp/mips.tar.bz2 && tar -xf mips.tar.bz2 && \
        wget https://minisatip.org/tmp/openwrt.tar.bz2 && tar -xf openwrt.tar.bz2 && \
        rm -rf *bz2

# install DVBCSA for ARM ... the other archs have it already in the toolchain
RUN : && \ 
	git clone https://github.com/catalinii/libdvbcsa && \
	cd libdvbcsa && \
        ./bootstrap && \
	./configure --host=arm-linux-gnueabihf && \
	make  && \
	cp ./src/.libs/libdvbcsa.a /usr/lib/arm-linux-gnueabi && \
	cp ./src/.libs/libdvbcsa.a /usr/lib/arm-linux-gnueabihf && \
        make clean && \
        ./configure --prefix=/usr && \
        make install && \
	cd .. && rm -rf libdvbcsa*gz && \
        curl -L -s https://www.openssl.org/source/openssl-1.1.1n.tar.gz  |  tar xzf - && \
        cd openssl-1.1.1n && ./Configure --cross-compile-prefix=arm-linux-gnueabihf- --prefix=/usr/arm-linux-gnueabihf/ linux-generic32 && \
        make install && \
        cd .. && rm -rf libdvbcsa*gz && \
        rm -rf openssl*
 

RUN git clone https://github.com/vdr-projects/vdr-plugin-mcli && \
	cd vdr-plugin-mcli && \
	make && \
	cp mcast/client/libmcli.so /usr/lib/

RUN --mount=type=secret,id=TOKEN2 \
    cp /run/secrets/TOKEN2 /etc/coverity && \
	mkdir /cov-analysis-linux64 && \
	wget https://scan.coverity.com/download/cxx/linux64 --post-data "token=$(cat /etc/coverity)&project=minisatip2" -O cov-analysis-linux64.tar.gz && \
	tar xzf cov-analysis-linux64.tar.gz --strip 1 -C /cov-analysis-linux64

ENV PATH="$PATH:/opt/STM/STLinux-2.4/devkit/sh4/bin:/opt/mips/mipsel-tuxbox-linux-gnu/bin/:/opt/toolchain-mips_24kc_gcc-5.4.0_musl-1.1.16/bin/:/cov-analysis-linux64/bin"
