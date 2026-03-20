#!/bin/bash

set -euo pipefail

DIR=/tmp/

# Create and use build directory
mkdir -p $DIR/libatomic_build
cd $DIR/libatomic_build

# Clean previous build
rm -rf *

# Configure libatomic with passed arguments
# CC and CXX are passed as environment variables
$DIR/libatomic/libatomic/configure --disable-multilib "$@"

make -j $(nproc)
make install
