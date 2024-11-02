#!/bin/bash

export PATH="/usr/local/opt/llvm/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/llvm/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include"

INSTALL_PATH=$HOME/cross/gnu
GCC_VERSION=gcc-14.2.0
# defauld in : xcrun --show-sdk-path
NATIVE_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk

# Does not work xcrun --show-sdk-path select what is the latest
# export CFLAGS="-isysroot $NATIVE_SYSROOT"
# export CXXFLAGS="-isysroot $NATIVE_SYSROOT"
# export LDFLAGS="-lgcc_s -lgcc"

mkdir -p $INSTALL_PATH/build
mkdir -p $INSTALL_PATH/tarballs
mkdir -p $INSTALL_PATH/sources

wget -P $INSTALL_PATH/tarballs -nc https://ftp.gnu.org/gnu/gcc/$GCC_VERSION/$GCC_VERSION.tar.gz

if [ ! -d "$INSTALL_PATH/sources/$GCC_VERSION" ]; then
    tar -xzvf $INSTALL_PATH/tarballs/$GCC_VERSION.tar.gz -C $INSTALL_PATH/sources
fi

mkdir -p $INSTALL_PATH/sources/$GCC_VERSION/build

cd $INSTALL_PATH/sources/$GCC_VERSION
./contrib/download_prerequisites

cd $INSTALL_PATH/sources/$GCC_VERSION/build
../$GCC_VERSION/configure \
    --prefix=$INSTALL_PATH/build \
    --enable-languages=c,c++ \
    --disable-multilib \
    --with-system-zlib \
    --with-sysroot=$NATIVE_SYSROOT \
