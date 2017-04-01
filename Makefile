BINUTILS=2.28

DESTDIR=$(shell pwd)/target

clean:
	rm -rf *~ binutils* *.tar.gz target

# binutils
binutils-${BINUTILS}.tar.gz:
	wget -c http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS}.tar.gz

binutils-${BINUTILS}/configure:	binutils-${BINUTILS}.tar.gz
	tar -xzvf binutils-${BINUTILS}.tar.gz

binutils-${BINUTILS}/build1/Makefile:	binutils-${BINUTILS}/configure
	mkdir -p binutils-${BINUTILS}/build1/
	cd binutils-${BINUTILS}/build1;../configure --prefix=${DESTDIR}/tools --with-sysroot=${DESTDIR} --with-lib-path=${DESTDIR}/tools/lib --target=$(uname -m) --disable-nls --disable-werror

target/tools/bin/*:	binutils-${BINUTILS}/build1/Makefile
	cd binutils-${BINUTILS}/build1;make -j 8
	mkdir -vp ${DESTDIR}/tools/lib
	cd ${DESTDIR}/tools;ln -sv lib lib64
	cd binutils-${BINUTILS}/build1;make install

