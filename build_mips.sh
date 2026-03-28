#!/bin/bash

set -euxo pipefail

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

# Clean up prefix and copy cross-compilation headers
rm -rf $MIPS_PREFIX
mkdir -p $MIPS_PREFIX/usr
cp -r /usr/mipsel-linux-gnu/include $MIPS_PREFIX/usr/

# Create installation directory for mips cross-compiler
mkdir -p $MIPS_PREFIX/lib

# Export paths for cross-compiler
export PATH=$MIPS_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$MIPS_PREFIX/usr/lib:${LD_LIBRARY_PATH:-}

echo "=== Building MIPS32r1 Cross-Compiler Toolchain ==="

# Build GCC prerequisites from source
echo "Building GCC prerequisites (GMP, MPFR, MPC)..."
PREREQ_PREFIX=$DIR/prerequisites
mkdir -p $PREREQ_PREFIX

# Build GMP
echo "Building GMP..."
rm -rf $DIR/gmp
mkdir -p $DIR/gmp
curl -L -s https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz | tar xJf - -C $DIR/gmp --strip-components=1
cd $DIR/gmp
./configure --prefix=$PREREQ_PREFIX
make -j $(nproc)
make install

# Build MPFR
echo "Building MPFR..."
rm -rf $DIR/mpfr
mkdir -p $DIR/mpfr
curl -L -s https://www.mpfr.org/mpfr-current/mpfr-4.2.2.tar.xz | tar xJf - -C $DIR/mpfr --strip-components=1
cd $DIR/mpfr
./configure --prefix=$PREREQ_PREFIX --with-gmp=$PREREQ_PREFIX
make -j $(nproc)
make install

# Build MPC
echo "Building MPC..."
rm -rf $DIR/mpc
mkdir -p $DIR/mpc
curl -L -s https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz | tar xzf - -C $DIR/mpc --strip-components=1
cd $DIR/mpc
./configure --prefix=$PREREQ_PREFIX --with-gmp=$PREREQ_PREFIX --with-mpfr=$PREREQ_PREFIX
make -j $(nproc)
make install

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
  --with-gmp=$PREREQ_PREFIX \
  --with-mpfr=$PREREQ_PREFIX \
  --with-mpc=$PREREQ_PREFIX

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
  --prefix=/usr \
  --host=$MIPS_TARGET \
  --build=$(gcc -dumpmachine) \
  --with-headers=$MIPS_PREFIX/usr/include \
  --enable-debug \
  --disable-versioning

make -j $(nproc)
make install DESTDIR=$MIPS_PREFIX

echo "glibc successfully built"

# Restore LD_LIBRARY_PATH for stage 2 GCC build (needed for libgmp, libmpfr, libmpc)
export LD_LIBRARY_PATH=$PREREQ_PREFIX/lib:$MIPS_PREFIX/usr/lib:${LD_LIBRARY_PATH:-}

# Build GCC stage 2 (full compiler with libstdc++)
echo "=== Building GCC stage 2 (full compiler with libstdc++) ==="
rm -rf $DIR/gcc_build
mkdir -p $DIR/gcc_build
cd $DIR/gcc_build

$GCC/configure \
  --cache-file=/dev/null \
  --prefix=$MIPS_PREFIX \
  --target=$MIPS_TARGET \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-nls \
  --with-arch=mips32 \
  --with-tune=mips32 \
  --with-float=soft \
  --with-abi=32 \
  --with-sysroot=$MIPS_PREFIX \
  --with-gmp=$PREREQ_PREFIX \
  --with-mpfr=$PREREQ_PREFIX \
  --with-mpc=$PREREQ_PREFIX

make -j $(nproc)
make install

echo "GCC stage 2 and libstdc++ successfully built"
echo "MIPS32 complete toolchain installed at: $MIPS_PREFIX"
