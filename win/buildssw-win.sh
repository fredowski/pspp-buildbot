#!/bin/sh -xve

# Download and install spread-sheet-widget

# Copyright (C) 2020 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

workdir=`pwd`

#Download and install spread-sheet-widget
sswversion=0.7
curl -o ssw.tgz http://alpha.gnu.org/gnu/ssw/spread-sheet-widget-$sswversion.tar.gz
tar -xzf ssw.tgz
cd spread-sheet-widget-$sswversion
mingw64-configure
mingw64-make -j4
mingw64-make install
mingw64-make distclean
mingw32-configure
mingw32-make -j4
mingw32-make install

