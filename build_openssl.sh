#!/bin/bash

set -euo pipefail

DIR=${BUILD_DIR:-/tmp}/

cd $DIR/openssl

# Extract PREFIX from arguments for cross-compiler PATH setup
PREFIX=""
for arg in "$@"; do
  case "$arg" in
    --prefix=*)
      PREFIX="${arg#--prefix=}"
      ;;
  esac
done

# If cross-compiling with a custom prefix, add the bin directory to PATH
if [ -n "$PREFIX" ] && [ "$PREFIX" != "/usr/local" ]; then
  if [ -d "$PREFIX/bin" ]; then
    export PATH="$PREFIX/bin:$PATH"
  fi
fi

./Configure $@
if [ $(echo $@| grep mips | wc -l | awk '{print $1;}') -gt 0 ]; then
	make EX_LIBS=-latomic  -j $(nproc)
else
	make -j $(nproc)
fi
make install_sw
make clean
