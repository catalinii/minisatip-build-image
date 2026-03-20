#!/bin/bash

set -euo pipefail

DIR=/tmp/

cd $DIR/srt

# Build with optional CMAKE_INSTALL_PREFIX and compiler settings
CMAKE_ARGS="-DENABLE_APPS=OFF"

if [ -n "${CMAKE_INSTALL_PREFIX:-}" ]; then
  CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
  # Use the same path as the prefix for finding dependencies (e.g., OpenSSL)
  CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX}"
  # Set PKG_CONFIG_PATH for finding OpenSSL via pkg-config
  export PKG_CONFIG_PATH="${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
fi

if [ -n "${CC:-}" ]; then
  CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_C_COMPILER=${CC}"
  # For MIPS, add -latomic flag needed for atomic operations
  if echo "${CC}" | grep -q "mips"; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_EXE_LINKER_FLAGS=-latomic -DCMAKE_SHARED_LINKER_FLAGS=-latomic"
  fi
fi

if [ -n "${CXX:-}" ]; then
  CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_CXX_COMPILER=${CXX}"
fi

# Create build directory
mkdir -p build
cd build

cmake $CMAKE_ARGS ..
make -j $(nproc)
make install
cd ..
rm -rf build
