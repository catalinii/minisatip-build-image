FROM jalle19/centos7-stlinux24:latest

FROM ubuntu:latest
COPY --from=0 /opt /opt

RUN apt-get update && apt-get install -f -y wget git binutils-arm-linux-gnueabihf autoconf automake make libtool gcc-10-arm-linux-gnueabihf gcc libc6-i386 libdvbcsa-dev

ENV PATH="$PATH:/opt/STM/STLinux-2.4/devkit/sh4/bin"

RUN bash -c "wget https://download.videolan.org/pub/videolan/libdvbcsa/1.1.0/libdvbcsa-1.1.0.tar.gz;tar xvf libdvbcsa-1.1.0.tar.gz;cd libdvbcsa-1.1.0;./configure --host=arm-linux-gnueabihf;make;cp ./src/.libs/libdvbcsa.a /usr/lib/arm-linux-gnueabi;cp ./src/.libs/libdvbcsa.a /usr/lib/arm-linux-gnueabihf/"

RUN bash -c "git clone https://github.com/catalinii/minisatip;cd minisatip;./configure --host=sh4-linux --enable-enigma;make;sleep 30"
