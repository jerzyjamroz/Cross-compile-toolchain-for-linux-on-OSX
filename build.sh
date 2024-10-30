#! /bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will configure, build and install a GCC cross-compiler.
# It assumes that all packages have been downloaded using download.sh before this file is run.
# Customize the variables (INSTALL_PATH, TARGET, etc.) in vars.sh to your liking before running.
# If you get an error and need to resume the script from some point in the middle,
# just delete/comment the preceding lines before running it again.
#
# See: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
#
# This script requires gnu-sed, not the normal sed that comes with OSX.  If you don't want to
# mess with the normal sed, perhaps add to the front of PATH the path to gnu-sed before you
# run this script?  e.g. export PATH=/path/to/gnu-sed-directory/bin:$PATH
#
# This script should be run in a case-sensitive partition which you can make using OSX's disk
# utility.
#-------------------------------------------------------------------------------------------

if [ ! -f ./vars.sh ]; then
    echo "This script must be run from the root of the working copy of the Cross-compile-toolchain-for-linux-on-OSX repo"
    exit 1
fi


source ./vars.sh

cd $FACTORY_ROOT
touch ./case_check

[[ -f "CASE_CHECK" ]] && { echo "Can't proceed on a case-insensitive filesystem"; rm -f ./case_check; exit 1; }

rm -f ./case_check


# Step 0.1 - Native Binutils
cd $FACTORY_ROOT
echo -e "\nStep 0.1 - native binutils...\n" && sleep 2
mkdir -p BUILD-NATIVE_BINUTILS
cd BUILD-NATIVE_BINUTILS
../SOURCES/$BINUTILS_VERSION/configure --prefix=$INSTALL_PATH --program-prefix=gnu- --with-tune=native --enable-plugin --enable-lto $CONFIGURATION_OPTIONS
make $PARALLEL_MAKE
make install




# Step 0.2. Native C/C++ Compilers
cd $FACTORY_ROOT
echo -e "\nStep 0.2 - native C/C++ compilers...\n" && sleep 2
mkdir -p BUILD-NATIVE_GCC
cd BUILD-NATIVE_GCC
../SRC_COMBINED-$GCC_VERSION/configure --prefix=$INSTALL_PATH --program-prefix=gnu- --with-build-time-tools=/usr/bin --with-tune=native --enable-languages=c,c++,lto --enable-plugin -v --enable-lto $CONFIGURATION_OPTIONS --with-native-system-header-dir=$NATIVE_SYSTEM_HEADER_DIR
make $PARALLEL_MAKE
make install


# Step 0.5 preparing SYSROOT
# Binutils and GCC builds look for headers and libraries in a
# specified sysroot directory.  Set up such a directory, with links
# into the install tree we're building.
# This is required since building with --with-sysroot will make the build system search into $SYSROOT/usr/include
# for headers to apply fixincludes to, and if that directory doesn't exist, make all-gcc will fail
cd $FACTORY_ROOT
echo -e "\nStep 0.5 - preparing SYSROOT...\n" && sleep 2
if [[ ! -d $SYSROOT ]]; then
    mkdir -p $SYSROOT/usr
    ln -s $INSTALL_PATH/$TARGET/include $SYSROOT/usr/include
    for z in etc lib sbin share
    do
        ln -s $INSTALL_PATH/$TARGET/$z $SYSROOT/$z
    done
fi

# Step 1. Binutils
cd $FACTORY_ROOT
echo -e "\nStep 1 - building cross binutils...\n" && sleep 2
mkdir -p BUILD-BINUTILS
cd BUILD-BINUTILS
../SOURCES/$BINUTILS_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET --with-sysroot=$SYSROOT $CONFIGURATION_OPTIONS
make $PARALLEL_MAKE
make install


# Step 2. Linux Kernel Headers
cd $FACTORY_ROOT
echo -e "\nStep 2 - Linux kernel headers...\n" && sleep 2
if [ $USE_NEWLIB -eq 0 ]; then
    cd SOURCES/$LINUX_KERNEL_VERSION
    make V=1 ARCH=$LINUX_ARCH CROSS_COMPILE=$TARGET- defconfig
    make V=1 ARCH=$LINUX_ARCH INSTALL_HDR_PATH=$INSTALL_PATH/$TARGET headers_install
fi



# Step 3. Minimal C/C++ Compilers for installing libc headers and compiling libc startup files
cd $FACTORY_ROOT
echo -e "\nStep 3 - Minimal C/C++ compilers...\n" && sleep 2
mkdir -p BUILD-GCC
cd BUILD-GCC
if [ $USE_NEWLIB -ne 0 ]; then
    NEWLIB_OPTION=--with-newlib
fi
../SRC_COMBINED-$GCC_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET --enable-languages=c,c++,lto --enable-plugin -v --enable-lto --without-headers --with-sysroot=$SYSROOT $CONFIGURATION_OPTIONS $NEWLIB_OPTION
make $PARALLEL_MAKE gcc_cv_libc_provides_ssp=yes all-gcc
make install-gcc




if [ $USE_NEWLIB -ne 0 ]; then
    # Steps 4-6: Newlib
    cd $FACTORY_ROOT
    echo -e "\nSteps 4-6 - newlib...\n" && sleep 2
    mkdir -p build-newlib
    cd build-newlib
    ../newlib-master/configure --prefix=$INSTALL_PATH --target=$TARGET $CONFIGURATION_OPTIONS
    make $PARALLEL_MAKE
    make install
    cd ..
else
    # Step 4. Standard C Library Headers and Startup Files
    cd $FACTORY_ROOT
    echo -e "\nStep 4 - standard lib headers and start files...\n" && sleep 2
    mkdir -p BUILD-GLIBC
    cd BUILD-GLIBC
    ../SOURCES/$GLIBC_VERSION/configure --prefix=$INSTALL_PATH/$TARGET --build=$MACHTYPE --host=$TARGET --target=$TARGET --with-headers=$INSTALL_PATH/$TARGET/include $CONFIGURATION_OPTIONS libc_cv_forced_unwind=yes
    make install-bootstrap-headers=yes install-headers
    make $PARALLEL_MAKE csu/subdir_lib
    install csu/crt1.o csu/crti.o csu/crtn.o $INSTALL_PATH/$TARGET/lib
    $TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $INSTALL_PATH/$TARGET/lib/libc.so
    touch $INSTALL_PATH/$TARGET/include/gnu/stubs.h


    # Step 5. Compiler Support Library
    cd $FACTORY_ROOT
    echo -e "\nStep 5 - building libgcc...\n" && sleep 2
    cd BUILD-GCC
    make $PARALLEL_MAKE all-target-libgcc
    make install-target-libgcc

    # Step 5.5. generate a proper include-fixed/limits.h as per http://www.linuxfromscratch.org/lfs/view/systemd/chapter05/gcc-pass2.html
    # "[...] the internal header that GCC installed is a partial, self-contained file and does not include the extended features of the system header.
    # This was adequate for building the temporary libc, but this build of GCC now requires the full internal header.
    # Create a full version of the internal header using a command that is identical to what the GCC build system does in normal circumstances:"
    # NOTE: Looking at the end of the output of "make ... all-gcc" in step 3, the relevant part, executed in BUILD-GCC/gcc, is the following:

    #------------------ PASTED FINAL OUTPUT FROM "make all-gcc" -------------------
    #set -e; for ml in `cat fixinc_list`; do \
    #	  sysroot_headers_suffix=`echo ${ml} | sed -e 's/;.*$//'`; \
    #	  multi_dir=`echo ${ml} | sed -e 's/^[^;]*;//'`; \
    #	  fix_dir=include-fixed${multi_dir}; \
    #	  if [ -f `echo /Volumes/develop/GNU_FACTORY/INSTALL/x86_64-linux-gnu/sys-root${sysroot_headers_suffix}/usr/include | sed -e :a -e 's,[^/]*/\.\.\/,,' -e ta`/limits.h ] ; then \
    #	    cat ../../SRC_COMBINED-gcc-6.3.0/gcc/limitx.h ../../SRC_COMBINED-gcc-6.3.0/gcc/glimits.h ../../SRC_COMBINED-gcc-6.3.0/gcc/limity.h > tmp-xlimits.h; \
    #	  else \
    #	    cat ../../SRC_COMBINED-gcc-6.3.0/gcc/glimits.h > tmp-xlimits.h; \
    #	  fi; \
    #	  /bin/sh ../../SRC_COMBINED-gcc-6.3.0/gcc/../mkinstalldirs ${fix_dir}; \
    #	  chmod a+rx ${fix_dir} || true; \
    #	  /bin/sh ../../SRC_COMBINED-gcc-6.3.0/gcc/../move-if-change \
    #	    tmp-xlimits.h  tmp-limits.h; \
    #	  rm -f ${fix_dir}/limits.h; \
    #	  cp -p tmp-limits.h ${fix_dir}/limits.h; \
    #	  chmod a+r ${fix_dir}/limits.h; \
    #	done
    #rm -f include-fixed/README
    #cp ../../SRC_COMBINED-gcc-6.3.0/gcc/../fixincludes/README-fixinc include-fixed/README
    #chmod a+r include-fixed/README
    #echo timestamp > stmp-int-hdrs
    #------------------ END OF PASTED OUTPUT -------------------

    # You can see that the "if [ -f .... ]" is the check for a limits.h to be already in INSTALL-PATH/TARGET/[SYSROOT/usr]/include,
    # which is not true at the moment and so the "cat gcc/limitx.h gcc/glimits.h gcc/litmity.h >... " dance is _NOT_ peformed and only the
    # "partial, self-contained" limits.h is copied in the include-fixed directory.
    # So we have to manually do that (right after the destination "include-fixed" has been created by step 5) as follows:

    # Step 5.5 generate proper include-fixed/limits.h
    cd $FACTORY_ROOT
    echo -e "\nStep 5.5 - Generating proper include-fixed/limits.h"  && sleep 2
    cd SRC_COMBINED-$GCC_VERSION
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > $(dirname $($TARGET-g++ -print-libgcc-file-name))/include-fixed/limits.h



    # Step 6. Standard C Library & the rest of Glibc
    cd $FACTORY_ROOT
    echo -e "\nStep 6 - standard C library and the rest of glibc...\n" && sleep 2
    cd BUILD-GLIBC
    make $PARALLEL_MAKE
    make install

fi

# Step 7. Standard C++ Library & the rest of GCC
#NOTE: We reconfigure here to remove the --without-headers configure option we used when making the core-xgcc needed to build libc
cd $FACTORY_ROOT
echo -e "\nStep 7 - building C++ library and rest of gcc\n"  && sleep 2
cd BUILD-GCC
../SRC_COMBINED-$GCC_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET --enable-languages=c,c++,lto --enable-plugin -v --enable-lto --with-sysroot=$SYSROOT $CONFIGURATION_OPTIONS $NEWLIB_OPTION
make $PARALLEL_MAKE all
make install



# Step 8. GDB
cd $FACTORY_ROOT
echo -e "\nStep 8 - GDB...\n" && sleep 2
mkdir -p BUILD-GDB
cd BUILD-GDB
../SRC_COMBINED-$GDB_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET --with-python --with-guile=no --with-sysroot=$SYSROOT
make $PARALLEL_MAKE all
make install

# Step 9. Workaround for absolute-path sysmlinks in sysroot folders
echo -e "\nStep 9 - Absolute-path symlinks workaround...\n" && sleep 2
EXTERNAL_SYSROOT="/Volumes/UbbyHD"
read -e -p "Enter absolute path to external sysroot [$EXTERNAL_SYSROOT]: " chosen_external_sysroot
if [[ ! -z "${chosen_external_sysroot/ //}" ]]; then
    EXTERNAL_SYSROOT="$chosen_external_sysroot"
fi
cd /
sudo mkdir -p lib
cd /lib
sudo ln -sf "${EXTERNAL_SYSROOT}/lib/${TARGET}"

trap - EXIT
echo 'Success!'
