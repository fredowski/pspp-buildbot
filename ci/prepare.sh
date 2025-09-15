#!/bin/sh -xve

# Prepare the build environment

# Copyright (C) 2020 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

#Download gnulib
gnulibver=11ec314e8d35829efac53b7a55a0a63fcabfadf1
curl -o gnulib.zip https://codeload.github.com/coreutils/gnulib/zip/$gnulibver
unzip -q gnulib.zip
rm gnulib.zip
mv gnulib-$gnulibver gnulib

