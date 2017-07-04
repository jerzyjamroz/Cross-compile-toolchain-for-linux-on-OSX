[ "$0" = "$BASH_SOURCE" ] && {
    echo "This script must be sourced"; exit 1
}

FACTORY_ROOT=$(cd ..; pwd)
INSTALL_PATH=/Users/abigagli/develop/GNU_FACTORY/INSTALL
#INSTALL_PATH=$FACTORY_ROOT/INSTALL
SYSROOT=$FACTORY_ROOT/SYSROOT
TARBALLS_PATH=$FACTORY_ROOT/TARBALLS
TARGET=x86_64-linux-gnu
USE_NEWLIB=0
LINUX_ARCH=x86_64

CONFIGURATION_OPTIONS="--disable-multilib --disable-nls --disable-werror" # --disable-threads --disable-shared

PARALLEL_MAKE=-j8
BINUTILS_VERSION=binutils-2.28
GCC_VERSION=gcc-7.1.0
GDB_VERSION=gdb-8.0
LINUX_KERNEL_VERSION=linux-3.16
GLIBC_VERSION=glibc-2.25
MPFR_VERSION=mpfr-3.1.5
GMP_VERSION=gmp-6.1.2
MPC_VERSION=mpc-1.0.3
ISL_VERSION=isl-0.16.1
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
export BUILD_CPPFLAGS='-I/opt/local/include'
export BUILD_LDFLAGS='-L/opt/local/lib -lintl'

