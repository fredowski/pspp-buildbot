#!/bin/bash -xve

# Retrieve the pspp test results from the build directory

newname=$1

lxc-info $newname
pwd
lxc-unpriv-attach -n $newname -- cat /home/pspp/build/tests/testsuite.log > testsuite.log
