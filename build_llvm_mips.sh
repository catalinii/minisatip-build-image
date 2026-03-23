#!/bin/bash

set -euo pipefail

DIR=/tmp/
INSTALL_PREFIX="${INSTALL_PREFIX:-/opt/clang-mips}"
MIPS_TARGET="mipsel-linux-gnu"
BUILD_JOBS=$(nproc)

echo "Building LLVM libraries for MIPS r1 cross-compilation"
echo "Install prefix: ${INSTALL_PREFIX}"
echo "Build jobs: ${BUILD_JOBS}"

# Download LLVM source if not present
if [ ! -d "$DIR/llvm-project" ]; then
    echo "Downloading LLVM 21.1.8 source..."
    cd "$DIR"
    curl -L -s "https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/llvm-project-21.1.8.src.tar.xz" | tar xJf -
    mv "llvm-project-21.1.8.src" llvm-project
fi

LLVM_SRC_DIR="$DIR/llvm-project"

# Create and enter build directory
BUILD_DIR="$DIR/llvm-mips-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
rm -rf *

echo "=== Configuring LLVM for MIPS ==="
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -DLLVM_TARGETS_TO_BUILD="Mips;X86" \
    -DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="${MIPS_TARGET}" \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_ORC=OFF \
    "${LLVM_SRC_DIR}/llvm"

echo "=== Compiling LLVM and Clang ==="
make -j "$BUILD_JOBS" clang compiler-rt

echo "=== Installing clang and compiler-rt ==="
make install-clang install-compiler-rt

echo "=== Building libc++ for MIPS ==="
# Now build libc++ with the new clang
LIBCXX_BUILD="$DIR/libcxx-mips-build"
mkdir -p "$LIBCXX_BUILD"
cd "$LIBCXX_BUILD"
rm -rf *

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}/${MIPS_TARGET}" \
    -DCMAKE_C_COMPILER="${INSTALL_PREFIX}/bin/clang" \
    -DCMAKE_CXX_COMPILER="${INSTALL_PREFIX}/bin/clang++" \
    -DCMAKE_C_COMPILER_TARGET="${MIPS_TARGET}" \
    -DCMAKE_CXX_COMPILER_TARGET="${MIPS_TARGET}" \
    -DCMAKE_SYSROOT="/usr/mipsel-linux-gnu" \
    -DLLVM_PATH="${LLVM_SRC_DIR}/llvm" \
    -DLIBCXX_CXX_ABI=none \
    -DLIBCXX_ENABLE_SHARED=ON \
    -DLIBCXX_ENABLE_STATIC=ON \
    "${LLVM_SRC_DIR}/libcxx"

echo "=== Compiling libc++ ==="
make -j "$BUILD_JOBS"

echo "=== Installing libc++ ==="
make install

echo ""
echo "=== Build Complete ==="
echo "Clang/LLVM for MIPS installed to: ${INSTALL_PREFIX}"
echo ""
echo "Binaries:"
ls -lah "${INSTALL_PREFIX}/bin/clang" "${INSTALL_PREFIX}/bin/clang++" 2>/dev/null || true
echo ""
echo "To use:"
echo "  export PATH=\"${INSTALL_PREFIX}/bin:\$PATH\""
echo "  export CC=\"${INSTALL_PREFIX}/bin/clang\""
echo "  export CXX=\"${INSTALL_PREFIX}/bin/clang++\""
