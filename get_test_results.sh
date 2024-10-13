#!/bin/bash -xve

# Retrieve the pspp test results from the build directory

newname=$1

lxc-info $newname
pwd
# Copy the testdir file from the container
scp -o StrictHostKeyChecking=no \
    -i /home/buildbot/pspp-buildbot/buildbot_rsa \
    pspp@`lxc-info -n $newname -i -H`:/home/pspp/build/tests/testsuite.log .
