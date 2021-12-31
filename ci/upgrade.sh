#!/bin/sh -xve

# Upgrade the debian sid distribution

# Copyright (C) 2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option


# Only upgrade if we are on sid
if ! grep -q sid /etc/debian_version ; then  
  exit
fi

export DEBIAN_FRONTEND=noninteractive 
echo 'libc6 libraries/restart-without-asking boolean true' | debconf-set-selections
apt update
apt -o Dpkg::Options::="--force-confold" dist-upgrade \
         -q -y --allow-downgrades --allow-remove-essential --allow-change-held-packages


