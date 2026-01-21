#! /bin/bash -e
DIR=/tmp/

cd $DIR
mkdir -p $DIR/openssl
git clone https://github.com/catalinii/libdvbcsa 
curl -L -s https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz | tar xzf - -C /tmp/openssl --strip-components=1
git clone https://github.com/vdr-projects/libnetceiver/

# Build libdvbcsa
./build_libdvbcsa.sh
./build_libdvbcsa.sh --host=arm-linux-gnueabihf --prefix=/usr/arm-linux-gnueabihf/
./build_libdvbcsa.sh --host=mipsel-linux-gnu --prefix=/usr/mipsel-linux-gnueabihf/

# Build openssl
./build_openssl.sh linux-generic64
./build_openssl.sh --cross-compile-prefix=arm-linux-gnueabihf- --prefix=/usr/arm-linux-gnueabihf/ linux-generic32
./build_openssl.sh --cross-compile-prefix=mipsel-linux-gnu- --prefix=/usr/mipsel-linux-gnueabihf/ linux-generic32

# Build netceiver (x64 only)
./build_netceiver.sh

ldconfig
