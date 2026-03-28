#!/bin/bash

set -euo pipefail

GCC_VERSION=15.2.0
BINUTILS_VERSION=2.43
BUILD_DIR=/tmp
MIPS_PREFIX=/opt/mipsel
MIPS_TARGET=mipsel-linux-gnu

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --prefix=*)
      MIPS_PREFIX="${arg#--prefix=}"
      ;;
    --prefix)
      MIPS_PREFIX_SET=true
      ;;
    --build-dir=*)
      BUILD_DIR="${arg#--build-dir=}"
      ;;
    --build-dir)
      BUILD_DIR_SET=true
      ;;
  esac
done

# Handle --prefix with separate value
if [[ "${MIPS_PREFIX_SET:-}" == "true" ]]; then
  shift
  MIPS_PREFIX="$1"
  shift
fi

# Handle --build-dir with separate value
if [[ "${BUILD_DIR_SET:-}" == "true" ]]; then
  shift
  BUILD_DIR="$1"
  shift
fi

# Set derived paths
GCC=$BUILD_DIR/gcc
DIR=$BUILD_DIR

# Create installation directory for mips cross-compiler
mkdir -p $MIPS_PREFIX
mkdir -p $MIPS_PREFIX/include
mkdir -p $MIPS_PREFIX/lib

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
  --without-headers \
  --with-gmp=/usr \
  --with-mpfr=/usr \
  --with-mpc=/usr

make -j $(nproc) all-gcc all-target-libgcc
make install-gcc install-target-libgcc

echo "GCC stage 1 successfully built"

# Build glibc for mips32
echo "=== Building glibc ==="
rm -rf $DIR/glibc
mkdir -p $DIR/glibc
curl -L -s https://ftp.gnu.org/gnu/glibc/glibc-2.41.tar.gz | tar xzf - -C $DIR/glibc --strip-components=1

mkdir -p $DIR/glibc/build
cd $DIR/glibc/build

# Unset LD_LIBRARY_PATH for glibc build (glibc configure doesn't like it)
unset LD_LIBRARY_PATH

CC=$MIPS_PREFIX/bin/$MIPS_TARGET-gcc \
CXX=$MIPS_PREFIX/bin/$MIPS_TARGET-g++ \
$DIR/glibc/configure \
  --prefix=$MIPS_PREFIX \
  --host=$MIPS_TARGET \
  --build=$(gcc -dumpmachine) \
  --with-headers=/usr/include \
  --enable-debug \
  --disable-versioning

make -j $(nproc)
make install

echo "glibc successfully built"

# Restore LD_LIBRARY_PATH for stage 2 GCC build (needed for libgmp, libmpfr, libmpc)
export LD_LIBRARY_PATH=$MIPS_PREFIX/lib:${LD_LIBRARY_PATH:-}

# Build GCC stage 2 (full compiler with libstdc++)
echo "=== Building GCC stage 2 (full compiler with libstdc++) ==="
cd $DIR/gcc_build
rm -rf *

$GCC/configure \
  --prefix=$MIPS_PREFIX \
  --target=$MIPS_TARGET \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-nls \
  --with-arch=mips32 \
  --with-tune=mips32 \
  --with-float=soft \
  --with-abi=32 \
  --with-sysroot=$MIPS_PREFIX

make -j $(nproc)
make install

echo "GCC stage 2 and libstdc++ successfully built"
echo "MIPS32 complete toolchain installed at: $MIPS_PREFIX"
