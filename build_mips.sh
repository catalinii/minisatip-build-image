#!/bin/bash

set -euo pipefail

GCC_VERSION=15.2.0
BINUTILS_VERSION=2.43
DIR=/tmp/
GCC=$DIR/gcc
MIPS_PREFIX=/opt/mipsel
MIPS_TARGET=mipsel-linux-gnu

# Parse --prefix argument if provided
for arg in "$@"; do
  case "$arg" in
    --prefix=*)
      MIPS_PREFIX="${arg#--prefix=}"
      ;;
    --prefix)
      # Handle --prefix with separate value
      MIPS_PREFIX_SET=true
      ;;
  esac
done

# Handle --prefix with separate value
if [[ "${MIPS_PREFIX_SET:-}" == "true" ]]; then
  shift
  MIPS_PREFIX="$1"
  shift
fi

# Create installation directory for mips cross-compiler
mkdir -p $MIPS_PREFIX

# Export paths for cross-compiler
export PATH=$MIPS_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$MIPS_PREFIX/lib:${LD_LIBRARY_PATH:-}

echo "=== Building MIPS32r1 Cross-Compiler Toolchain ==="

# Download and build binutils first (required for GCC cross-compilation)
echo "Building binutils..."
rm -rf $DIR/binutils
mkdir -p $DIR/binutils
curl -L -s https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz | tar xzf - -C $DIR/binutils --strip-components=1

mkdir -p $DIR/binutils/build
cd $DIR/binutils/build
../configure --prefix=$MIPS_PREFIX --target=$MIPS_TARGET --disable-nls --disable-werror
make -j $(nproc)
make install

# Download GCC source
echo "Downloading GCC $GCC_VERSION..."
mkdir -p $GCC
curl -L -s https://gcc.gnu.org/pub/gcc/releases/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C $GCC --strip-components=1

# Build GCC stage 1 (compiler only)
echo "Building GCC stage 1 (compiler only)..."
mkdir -p $DIR/gcc_build
cd $DIR/gcc_build
$GCC/configure \
  --prefix=$MIPS_PREFIX \
  --target=$MIPS_TARGET \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-nls \
  --disable-threads \
  --disable-shared \
  --with-arch=mips32 \
  --with-tune=mips32 \
  --with-float=soft \
  --with-abi=32 \
  --without-headers

make -j $(nproc) all-gcc all-target-libgcc
make install-gcc install-target-libgcc

echo "GCC stage 1 successfully built"
echo "MIPS32r1 toolchain installed at: $MIPS_PREFIX"
