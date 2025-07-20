#! /bin/bash -e
DIR=/tmp/

cd $DIR
mkdir -p $DIR/openssl
git clone https://github.com/catalinii/libdvbcsa 
curl -L -s https://www.openssl.org/source/openssl-1.1.1n.tar.gz  |  tar xzf - -C /tmp/openssl --strip-components=1
git clone https://github.com/vdr-projects/libnetceiver/

declare -a flags
flags[0]="--host=arm-linux-gnueabihf --prefix=/usr/arm-linux-gnueabihf/,--cross-compile-prefix=arm-linux-gnueabihf- --prefix=/usr/arm-linux-gnueabihf/ linux-generic32"
flags[1]="--host=mipsel-linux-gnu --prefix=/sysroot/mipsel,--cross-compile-prefix=mipsel-linux-gnu- --prefix=/sysroot/mipsel linux-generic32"
flags[2]=",linux-generic64"
for flag in "${flags[@]}"
do
        IFS="," read -r -a arr <<< "${flag}"
        cd $DIR/libdvbcsa 
        ./bootstrap 
        ./configure ${arr[0]}
        make install 
        make clean
	cd $DIR/openssl
        ./Configure ${arr[1]}
        make install
        make clean	
done

cd $DIR/libnetceiver
make install

ldconfig
