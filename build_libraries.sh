#! /bin/bash -e
DIR=/tmp/
BASEDIR=$(dirname "$0")

cd $DIR
rm -rf srt libdvbcsa libnetceiver openssl libatomic
mkdir -p $DIR/openssl
git clone https://github.com/catalinii/libdvbcsa
curl -L -s https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz | tar xzf - -C /tmp/openssl --strip-components=1
git clone https://github.com/vdr-projects/libnetceiver/
git clone https://github.com/Haivision/srt
mkdir -p $DIR/libatomic
curl -L -s https://gcc.gnu.org/pub/gcc/releases/gcc-14.2.0/gcc-14.2.0.tar.xz | tar xJf - -C /tmp/libatomic --strip-components=1

# Build libdvbcsa
$BASEDIR/build_libdvbcsa.sh
$BASEDIR/build_libdvbcsa.sh --host=arm-linux-gnueabihf --prefix=/usr/arm-linux-gnueabihf/
$BASEDIR/build_libdvbcsa.sh --host=mipsel-linux-gnu --prefix=/usr/mipsel-linux-gnu/

# Build openssl
$BASEDIR/build_openssl.sh linux-generic64
$BASEDIR/build_openssl.sh --cross-compile-prefix=arm-linux-gnueabihf- --prefix=/usr/arm-linux-gnueabihf/ linux-generic32
$BASEDIR/build_openssl.sh --cross-compile-prefix=mipsel-linux-gnu- --prefix=/usr/mipsel-linux-gnu/ linux-generic32

# Build libatomic
CC=mipsel-linux-gnu-gcc CXX=mipsel-linux-gnu-g++ $BASEDIR/build_libatomic.sh --host=mipsel-linux-gnu --prefix=/usr/mipsel-linux-gnu/

# Build netceiver (x64 only)
$BASEDIR/build_netceiver.sh

# Build srt
$BASEDIR/build_srt.sh
CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ CMAKE_INSTALL_PREFIX=/usr/arm-linux-gnueabihf/ $BASEDIR/build_srt.sh
CC=mipsel-linux-gnu-gcc CXX=mipsel-linux-gnu-g++ CMAKE_INSTALL_PREFIX=/usr/mipsel-linux-gnu/ $BASEDIR/build_srt.sh

ldconfig
