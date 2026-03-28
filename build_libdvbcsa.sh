#!/bin/bash

set -euo pipefail

DIR=${BUILD_DIR:-/tmp}/

cd $DIR/libdvbcsa 
./bootstrap 
./configure $@
make -j $(nproc)
make install
make clean
