#!/bin/sh -xve

# Copy the build results from the windows build container to the download folder

# Copyright (C) 2020,2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option


resdir=/proc/$(lxc-info -n windows-run -p -H)/root/home/pspp/results
# The results directory should contain a directory in the format YY-MM-DD-version-commit
dateversion=`ls $resdir`
downloaddir=/home/buildbot/www/downloads/windows/pspp-win-daily
cp -R $resdir/* $downloaddir

echo "Download: https://caeis.etech.fh-augsburg.de/downloads/windows/pspp-win-daily/$dateversion"


