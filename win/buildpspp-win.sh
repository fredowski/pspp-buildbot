#!/bin/sh -xve

# Crossbuild pspp for windows
# Run this insided the build vm

# Copyright (C) 2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

workdir=`pwd`

sandboxdir=/home/pspp/sandbox

curl -L -o pspp.tgz https://benpfaff.org/~blp/pspp-master/latest-source.tar.gz
tar -xzf pspp.tgz
psppversion=`ls -d pspp-* | sed -n 's/pspp-\(.*\)/\1/p'`
cd pspp-$psppversion/Windows
./build-dependencies --arch=x86_64-w64-mingw32 --sandbox=$sandboxdir --no-clean
cd
mkdir build
cd build
../pspp-$psppversion/configure --host="x86_64-w64-mingw32" \
  CPPFLAGS="-I$sandboxdir/Install/include" \
  LDFLAGS="-L$sandboxdir/Install/lib" \
  PKG_CONFIG_LIBDIR="$sandboxdir/Install/lib/pkgconfig" \
  --prefix=$sandboxdir/psppinst \
  --enable-relocatable
make -j4
make install
make install-html
make install-pdf
make Windows/installers
cd
mkdir -p results/$psppversion
cp build/Windows/*.exe results/$psppversion
chmod -R a+rx results
chmod a+rx .

