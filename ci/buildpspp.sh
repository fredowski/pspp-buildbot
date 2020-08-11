#!/bin/bash -xve

# Build pspp from night build distribution package

# Copyright (C) 2020 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

curl -o pspp.tgz https://benpfaff.org/~blp/pspp-master/latest-source.tar.gz
#curl -L -o pspp.tgz http://ftpmirror.gnu.org/pspp/pspp-1.2.0.tar.gz
tar -xzf pspp.tgz
rm pspp.tgz
mv pspp* pspp
mkdir build
cd build
../pspp/configure --prefix=/usr --libdir=/usr/lib64
make -j8
