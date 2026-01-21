#!/bin/bash

set -euo pipefail

DIR=/tmp/

cd $DIR/openssl
./Configure $@
if [ $(echo $@| grep mips | wc -l | awk '{print $1;}') -gt 0 ]; then
	make EX_LIBS=-latomic  -j $(nproc)
else
	make -j $(nproc)
fi
make install_sw
make clean
