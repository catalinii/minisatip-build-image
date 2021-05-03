FROM jalle19/centos7-stlinux24:latest

FROM ubuntu:latest
COPY --from=0 /opt /opt

# install ARM cross compiler
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -f -y wget git binutils-arm-linux-gnueabihf autoconf automake make libtool gcc-arm-linux-gnueabihf gcc libc6-i386 bzip2 lib32z1 dvb-apps libssl-dev pkg-config g++ vdr-dev zlib1g-dev libxml2-dev

# install MIPS arch: openwrt and enigma based
RUN cd /opt && \
	wget https://minisatip.org/tmp/mips.tar.bz2 && tar -xf mips.tar.bz2 && \
        wget https://minisatip.org/tmp/openwrt.tar.bz2 && tar -xf openwrt.tar.bz2 && \
        rm -rf *bz2

ENV PATH="$PATH:/opt/STM/STLinux-2.4/devkit/sh4/bin:/opt/mips/mipsel-tuxbox-linux-gnu/bin/:/opt/toolchain-mips_24kc_gcc-5.4.0_musl-1.1.16/bin/"

# install DVBCSA for ARM ... the other archs have it already in the toolchain
RUN : && \ 
	wget https://download.videolan.org/pub/videolan/libdvbcsa/1.1.0/libdvbcsa-1.1.0.tar.gz && \
	tar xvf libdvbcsa-1.1.0.tar.gz && \
	cd libdvbcsa-1.1.0 && \
	./configure --host=arm-linux-gnueabihf && \
	make  && \
	cp ./src/.libs/libdvbcsa.a /usr/lib/arm-linux-gnueabi && \
	cp ./src/.libs/libdvbcsa.a /usr/lib/arm-linux-gnueabihf && \
        make clean && \
        ./configure && \
        make install && \
	cd .. && rm -rf kibdvbcsa*

RUN git clone https://github.com/vdr-projects/vdr-plugin-mcli && \
	cd vdr-plugin-mcli && \
	make install
