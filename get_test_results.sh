#!/bin/bash -xve

# Retrieve the pspp test results from the build directory

newname=$1

lxc-info $newname
pwd
# Copy the testdir file from the container
cp /proc/$(lxc-info -n $newname -p -H)/root/home/pspp/build/tests/testsuite.log .
