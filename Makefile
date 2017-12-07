NUMPROCS=9

KERNEL=4.14.12
BINUTILS=2.29.1
MPFR=3.1.6
GMP=6.1.2
MPC=1.0.3
GCC=7.2.0
GLIBC=2.26

DESTDIR=$(shell pwd)/target

clean:
	rm -rf *~ binutils* *.tar.gz target mpfr* gcc* gmp* gccfix.sh linux* glibc*

# binutils
binutils.tar.gz:
	wget -c http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS}.tar.gz 
	ln -f -s binutils-${BINUTILS}.tar.gz binutils.tar.gz
	touch binutils.tar.gz

binutils/configure:	binutils.tar.gz
	tar -xf binutils.tar.gz
	ln -f -s binutils-${BINUTILS} binutils
	find binutils -print0|xargs -0 touch

binutils/build1/Makefile:	binutils/configure
	mkdir -p binutils/build1/
	cd binutils/build1;../configure --prefix=${DESTDIR}/tools --with-sysroot=${DESTDIR} --with-lib-path=${DESTDIR}/tools/lib --target=$(uname -m) --disable-nls --disable-werror

target/tools/bin/*:	binutils/build1/Makefile
	cd binutils/build1;make -j ${NUMPROCS}
	mkdir -vp ${DESTDIR}/tools/lib
	cd ${DESTDIR}/tools;ln -f -sv lib lib64
	cd binutils/build1;make install

# mpfr
mpfr.tar.gz:
	wget -c http://www.mpfr.org/mpfr-current/mpfr-${MPFR}.tar.gz
	ln -f -s mpfr-${MPFR}.tar.gz mpfr.tar.gz
	touch mpfr.tar.gz

# gmp
gmp.tar.xz:
	wget -c https://gmplib.org/download/gmp/gmp-${GMP}.tar.xz
	ln -f -s gmp-${GMP}.tar.xz gmp.tar.xz
	touch gmp.tar.xz

# mpc
mpc.tar.gz:
	wget -c https://ftp.gnu.org/gnu/mpc/mpc-${MPC}.tar.gz
	ln -f -s mpc-${MPC}.tar.gz mpc.tar.gz
	touch mpc.tar.gz

# gcc
gcc.tar.gz:
	wget -c https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC}/gcc-${GCC}.tar.gz
	ln -f -s gcc-${GCC}.tar.gz gcc.tar.gz
	touch gcc.tar.gz

gcc:	gcc.tar.gz gccfix.sh
	tar -xf gcc.tar.gz
	ln -f -s gcc-${GCC} gcc
	find gcc -print0|xargs -0 touch
	cd gcc;bash ../gccfix.sh

gccfix.sh:
	@echo "for file in gcc/config/{linux,i386/linux{,64}}.h" > gccfix.sh
	@echo "do" >> gccfix.sh
	@echo "  cp -uv \$$file{,.orig} " >> gccfix.sh
	@echo "    sed -e 's@/lib\\(64\\)\\?\\(32\\)\\?/ld@${DESTDIR}/tools&@g' -e 's@/usr@${DESTDIR}/tools@g' \$$file.orig > \$$file" >> gccfix.sh
	@echo "  echo '" >> gccfix.sh
	@echo "#undef STANDARD_STARTFILE_PREFIX_1" >> gccfix.sh
	@echo "#undef STANDARD_STARTFILE_PREFIX_2" >> gccfix.sh
	@echo "#define STANDARD_STARTFILE_PREFIX_1 \"${DESTDIR}/tools/lib/\"" >> gccfix.sh
	@echo "#define STANDARD_STARTFILE_PREFIX_2 \"\"' >> \$$file " >> gccfix.sh
	@echo "  touch \$$file.orig" >> gccfix.sh
	@echo "done" >> gccfix.sh

gcc/mpfr:	mpfr.tar.gz gcc
	cd gcc;tar -xf ../mpfr.tar.gz
	cd gcc;find mpfr-${MPFR} -print0|xargs -0 touch
	cd gcc;ln -f -s mpfr-${MPFR} mpfr

gcc/gmp:	gmp.tar.xz gcc
	cd gcc;tar -xf ../gmp.tar.xz
	cd gcc;find gmp-${GMP} -print0|xargs -0 touch
	cd gcc;ln -f -s gmp-${GMP} gmp

gcc/mpc:	mpc.tar.gz gcc
	cd gcc;tar -xf ../mpc.tar.gz
	cd gcc;find mpc-${MPC} -print0|xargs -0 touch
	cd gcc;ln -f -s mpc-${MPC} mpc

gcc/build:	gcc
	mkdir -p gcc/build

gcc/build/Makefile:	gcc/build gcc/mpfr gcc/gmp gcc/mpc gcc/mpfr target/tools/bin/*
	cd gcc/build;../configure                                       \
    --target=$(uname -m)                           \
    --prefix=${DESTDIR}/tools                      \
    --with-glibc-version=2.11                      \
    --with-sysroot=${DESTDIR}                      \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
 
# linux

linux.tar.xz:
	wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL}.tar.xz
	ln -f -s linux-${KERNEL}.tar.xz linux.tar.xz

linux:	linux.tar.xz
	tar -xf linux.tar.xz
	ln -f -s linux-${KERNEL} linux

linux/.config:	linux
	cd linux;make defconfig

linux/dest/include/*:	linux/.config
	cd linux;make mrproper
	cd linux;make INSTALL_HDR_PATH=dest headers_install

target/tools/include/*:	linux/dest/include/*
	cp -rv linux/dest/include/* target/tools/include

# glibc

glibc-${GLIBC}.tar.gz:
	wget -c http://mirrors.peers.community/mirrors/gnu/libc/glibc-${GLIBC}.tar.gz

glibc.tar.gz:	glibc-${GLIBC}.tar.gz
	ln -f -s glibc-${GLIBC}.tar.gz glibc.tar.gz
