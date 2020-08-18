#!/bin/bash -xve

# Build pspp from Ben's nightly build distribution package

# Copyright (C) 2020 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

workdir=`pwd`

curl -o pspp.tgz https://benpfaff.org/~blp/pspp-master/latest-source.tar.gz
#curl -L -o pspp.tgz http://ftpmirror.gnu.org/pspp/pspp-1.2.0.tar.gz
tar -xzf pspp.tgz
rm pspp.tgz
mv pspp* pspp
mkdir build
cd build
# PKG_CONFIG_PATH for the spread-sheet-widget
../pspp/configure --prefix=$workdir/install PKG_CONFIG_PATH=$workdir/install/lib/pkgconfig
make -j8
