#!/bin/bash -xve

name="debian-sid"
buildvm="$name-build"

# Set the default file creation mode to readable for all
umask 22

lxc-info -n $name
lxc-copy --name $name --newname $buildvm
systemd-run --user -p "Delegate=yes" lxc-start -F $buildvm
sleep 15
lxc-attach -n $buildvm -- su pspp -c "cd; git clone https://github.com/fredowski/pspp.git"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; git checkout travis"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; ./ci/prepare.sh"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; ./ci/buildssw.sh"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; make -f Smake"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; ./ci/buildpspp-linux.sh"
