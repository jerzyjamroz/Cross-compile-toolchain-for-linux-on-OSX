#! /bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will download packages for a GCC cross-compiler.
# Customize the variables (INSTALL_PATH, TARGET, etc.) in vars.sh to your liking before running.
#
# See: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
#-------------------------------------------------------------------------------------------

source ./vars.sh

mkdir -p $TARBALLS_PATH
cd $TARBALLS_PATH
# Download packages
export http_proxy=$HTTP_PROXY https_proxy=$HTTP_PROXY ftp_proxy=$HTTP_PROXY
wget -nc https://ftp.gnu.org/gnu/binutils/$BINUTILS_VERSION.tar.gz
wget -nc https://ftp.gnu.org/gnu/gcc/$GCC_VERSION/$GCC_VERSION.tar.gz
if [ $USE_NEWLIB -ne 0 ]; then
    wget -nc -O newlib-master.zip https://github.com/bminor/newlib/archive/master.zip || true
    unzip -qo newlib-master.zip
else
    wget -nc --no-check-certificate https://www.kernel.org/pub/linux/kernel/v3.x/$LINUX_KERNEL_VERSION.tar.xz
    wget -nc https://ftp.gnu.org/gnu/glibc/$GLIBC_VERSION.tar.xz
fi
wget -nc https://ftp.gnu.org/gnu/mpfr/$MPFR_VERSION.tar.xz
wget -nc https://ftp.gnu.org/gnu/gmp/$GMP_VERSION.tar.xz
wget -nc https://ftp.gnu.org/gnu/mpc/$MPC_VERSION.tar.gz
wget -nc ftp://gcc.gnu.org/pub/gcc/infrastructure/$ISL_VERSION.tar.bz2
wget -nc ftp://gcc.gnu.org/pub/gcc/infrastructure/$CLOOG_VERSION.tar.gz

mkdir -p ../SOURCES
# Extract everything
for f in *.tar*; do tar -C ../SOURCES -xkf $f; done

cd $FACTORY_ROOT

# Prepare a "combined source" gcc sourcetree
mkdir -p SRC_COMBINED-$GCC_VERSION
cd SRC_COMBINED-$GCC_VERSION
ln -sf ../SOURCES/$GCC_VERSION/* .
ln -sf `ls -1d ../SOURCES/mpfr-*/` mpfr
ln -sf `ls -1d ../SOURCES/gmp-*/` gmp
ln -sf `ls -1d ../SOURCES/mpc-*/` mpc
ln -sf `ls -1d ../SOURCES/isl-*/` isl
ln -sf `ls -1d ../SOURCES/cloog-*/` cloog
cd ..

trap - EXIT
echo 'Success!'
