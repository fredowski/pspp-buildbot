#!/bin/sh -xve

# Copy the build results from Harry to the download folder

# Copyright (C) 2020 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

rm -rf /home/buildbot/www/downloads/pspp-win-daily
cp -R /proc/$(lxc-info -n windows-run -p -H)/root/home/pspp/pspp-master-*/Upload/20* \
/home/buildbot/www/downloads/pspp-win-daily
