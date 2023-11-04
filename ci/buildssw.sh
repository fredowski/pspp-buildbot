#!/bin/sh -xve

# Download and install spread-sheet-widget

# Copyright (C) 2020,2022 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

workdir=`pwd`

#Download and install spread-sheet-widget
sswversion=0.10
curl -o ssw.tgz http://alpha.gnu.org/gnu/ssw/spread-sheet-widget-$sswversion.tar.gz
tar -xzf ssw.tgz
cd spread-sheet-widget-$sswversion
./configure --prefix=$workdir/install
make -j4
make install

