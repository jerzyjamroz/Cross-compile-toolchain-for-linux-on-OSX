
GCC_VERSION=gcc-14.2.0
# defauld in : xcrun --show-sdk-path
NATIVE_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk

# Does not work xcrun --show-sdk-path select what is the latest
# export CFLAGS="-isysroot $NATIVE_SYSROOT"
# export CXXFLAGS="-isysroot $NATIVE_SYSROOT"
# export LDFLAGS="-lgcc_s -lgcc"

mkdir build && cd build

../$GCC_VERSION/configure \
    --prefix=$HOME/tmp/install/$GCC_VERSION \
    --enable-languages=c,c++ \
    --disable-multilib \
    --with-system-zlib \
    --with-sysroot=$NATIVE_SYSROOT \
