BINUTILS=2.28

DESTDIR=$(shell pwd)/target

clean:
	rm -rf *~ binutils* *.tar.gz target

# binutils
binutils.tar.gz:
	wget -c http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS}.tar.gz -O binutils.tar.gz

binutils/configure:	binutils.tar.gz
	tar -xzvf binutils.tar.gz
	ln -s binutils-${BINUTILS} binutils

binutils/build1/Makefile:	binutils/configure
	mkdir -p binutils/build1/
	cd binutils/build1;../configure --prefix=${DESTDIR}/tools --with-sysroot=${DESTDIR} --with-lib-path=${DESTDIR}/tools/lib --target=$(uname -m) --disable-nls --disable-werror

target/tools/bin/*:	binutils/build1/Makefile
	cd binutils/build1;make -j 8
	mkdir -vp ${DESTDIR}/tools/lib
	cd ${DESTDIR}/tools;ln -sv lib lib64
	cd binutils/build1;make install

