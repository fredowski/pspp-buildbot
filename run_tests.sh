#!/bin/bash -xve

# Run "make check"

newname=$1
umask 22

lxc-info $newname
# Copy the testdir file from the container
lxc-attach -n $newname -- su pspp -c "cd ~/build; make check"
