#! /bin/bash -ex
BUILD_DIR=/tmp
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

# Parse --build-dir argument if provided
for arg in "$@"; do
  case "$arg" in
    --build-dir=*)
      BUILD_DIR="${arg#--build-dir=}"
      ;;
    --build-dir)
      BUILD_DIR_SET=true
      ;;
  esac
done

# Handle --build-dir with separate value
if [[ "${BUILD_DIR_SET:-}" == "true" ]]; then
  shift
  BUILD_DIR="$1"
  shift
fi

export BUILD_DIR
cd $BUILD_DIR
rm -rf srt libdvbcsa libnetceiver openssl
mkdir -p $BUILD_DIR/openssl
git clone https://github.com/catalinii/libdvbcsa
curl -L -s https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz | tar xzf - -C $BUILD_DIR/openssl --strip-components=1
git clone https://github.com/vdr-projects/libnetceiver/
git clone https://github.com/Haivision/srt

# Build libdvbcsa
$BASEDIR/build_libdvbcsa.sh 2>&1 | tail -200
$BASEDIR/build_libdvbcsa.sh --host=arm-linux-gnueabihf --prefix=/usr/arm-linux-gnueabihf/ 2>&1 | tail -200
$BASEDIR/build_libdvbcsa.sh --host=mipsel-linux-gnu --prefix=/opt/mipsel/usr 2>&1 | tail -200

# Build openssl
$BASEDIR/build_openssl.sh linux-generic64 2>&1 | tail -200
$BASEDIR/build_openssl.sh --cross-compile-prefix=arm-linux-gnueabihf- --prefix=/usr/arm-linux-gnueabihf/ linux-generic32 2>&1 | tail -200
$BASEDIR/build_openssl.sh --cross-compile-prefix=mipsel-linux-gnu- --prefix=/opt/mipsel/usr linux-generic32

# Build netceiver (x64 only)
$BASEDIR/build_netceiver.sh

# Build srt
$BASEDIR/build_srt.sh
CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ CMAKE_INSTALL_PREFIX=/usr/arm-linux-gnueabihf/ $BASEDIR/build_srt.sh
CC=mipsel-linux-gnu-gcc CXX=mipsel-linux-gnu-g++ CMAKE_INSTALL_PREFIX=/opt/mipsel/usr $BASEDIR/build_srt.sh

ldconfig
