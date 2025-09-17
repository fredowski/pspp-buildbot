#!/bin/sh -xve

# Copy the build results from the windows build container to the download folder

# Copyright (C) 2020,2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option


resdir=/proc/$(lxc-info -n windows-run -p -H)/root/home/pspp/results
psppversion=`ls $resdir`
today=`date "+%Y-%m-%d"`
downloaddir=/home/buildbot/www/downloads/windows/pspp-win-daily/$today-$psppversion
mkdir -p $downloaddir
cp -R $resdir/$psppversion/* $downloaddir

echo "Download: https://caeis.etech.fh-augsburg.de/downloads/windows/pspp-win-daily/$today-$psppversion"


