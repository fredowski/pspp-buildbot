#!/bin/sh -xve

# Build pspp from git

# Copyright (C) 2020 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

workdir=`pwd`
# The source tree for pspp is here.
cd pspp

# Retrieve and Set Version Info
gitversion=`git log --pretty=format:"%h" -1`
repoversion=`sed -n 's/AC_INIT.*\[\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' configure.ac`
psppversion=$repoversion-g$gitversion

cd $workdir
# Configure and build pspp
mkdir ./build
cd build
../pspp/configure --without-perl-module --prefix=$workdir/install PKG_CONFIG_PATH=$workdir/install/lib/pkgconfig
make -j8 VERSION=$psppversion
