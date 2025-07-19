#!/bin/bash

set -euo pipefail

DIR=/tmp/

cd $DIR/openssl
./Configure $@
make -j $(nproc)
make install_sw
make clean
