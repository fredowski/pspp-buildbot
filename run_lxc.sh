#!/bin/bash -xve

name="debian-buster"
# Set the default file creation mode to readable for all
umask 22

lxc-info -n $name
lxc-copy --name $name --newname vm1
systemd-run --user -r -p "Delegate=yes" lxc-start -F vm1
sleep 15
lxc-attach -n vm1 -- su pspp -c "cd; git clone https://github.com/fredowski/pspp.git"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; git checkout travis"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; ./ci/prepare.sh"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; ./ci/buildssw.sh"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; make -f Smake"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; ./ci/buildpspp-linux.sh"
