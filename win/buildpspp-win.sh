#!/bin/sh -xve

# Crossbuild pspp for windows
# Run this insided the build vm

# Copyright (C) 2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

workdir=`pwd`

sandboxdir=/home/pspp/sandbox

curl -L -o pspp.tgz https://benpfaff.org/~blp/pspp-master/latest-source.tar.gz
#Extract the creation date in the format YYYY-MM-DD
TZ=UTC srcdate=`stat -c "%y" pspp.tgz | cut -d ' ' -f1`
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
mkdir -p results/$srcdate-$psppversion
cp build/Windows/*.exe results/$srcdate-$psppversion
chmod -R a+rx results
chmod a+rx .

