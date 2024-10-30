# The configuration modification file
# Requirements: coreutils wget gmp mpfr libmpc

[ "$0" = "$BASH_SOURCE" ] && {
    echo "This script must be sourced"; exit 1
}

#FACTORY_ROOT=$(cd ..; pwd)
FACTORY_ROOT=$HOME/cross/osx2linux
INSTALL_PATH=$FACTORY_ROOT/GNU_FACTORY/INSTALL-gcc-7.2
#INSTALL_PATH=$FACTORY_ROOT/INSTALL
SYSROOT=$FACTORY_ROOT/SYSROOT
TARBALLS_PATH=$FACTORY_ROOT/TARBALLS
TARGET=x86_64-linux-gnu
USE_NEWLIB=0
LINUX_ARCH=x86_64

#it has to be changed from /usr/include to: native_system_header_dir=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include
#NATIVE_SYSTEM_HEADER_DIR=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include
#--with-native-system-header-dir=$NATIVE_SYSTEM_HEADER_DIR
# alternatively NATIVE_SYSROOT can be used
NATIVE_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
# It cant be global as it affects all builds
NATIVE_CPP=/usr/bin/cpp

#CONFIGURATION_OPTIONS="--disable-multilib --disable-nls --disable-werror" # --disable-threads --disable-shared #--with-sysroot=$NATIVE_SYSROOT
CONFIGURATION_OPTIONS="--disable-multilib --disable-nls --disable-werror --with-sysroot=$NATIVE_SYSROOT"

PARALLEL_MAKE=-j$(nproc)
BINUTILS_VERSION=binutils-2.29.1
GCC_VERSION=gcc-7.2.0
GDB_VERSION=gdb-8.0.1
LINUX_KERNEL_VERSION=linux-4.4
GLIBC_VERSION=glibc-2.26
MPFR_VERSION=mpfr-3.1.6
GMP_VERSION=gmp-6.1.2
MPC_VERSION=mpc-1.0.3
ISL_VERSION=isl-0.18
CLOOG_VERSION=cloog-0.18.1

readlink ()
{
    greadlink "$@"
}
export -f readlink

sed ()
{
    gsed "$@"
}
export -f sed

export PATH=$INSTALL_PATH/bin:$PATH
# extra flags and env variables are needed to get this to compile on OSX
export HOST_EXTRACFLAGS="-I$PWD/endian"

# these are needed for gettext and assuming that it was installed using brew
export BUILD_CPPFLAGS="-I$HOMEBREW_PREFIX/include"
export BUILD_LDFLAGS="-L$HOMEBREW_PREFIX/lib -lintl"

#export CPPFLAGS="-I$HOMEBREW_PREFIX/include"
#export LDFLAGS="-L$HOMEBREW_PREFIX/lib -lintl"
