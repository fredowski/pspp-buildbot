#!/bin/bash -xve

name="opensuse"
newname="vm2"

lxc-copy --name $name --newname vm2
systemd-run --user -r -p "Delegate=yes" lxc-start -F vm2
# Wait for network to be ready
sleep 15
# Copy the files in directory ./ci into the container
cd ~/pspp-buildbot
tar -c ./ci | lxc-attach -n vm2 -- tar -C /home/pspp -vx
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/prepare.sh"
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/buildssw.sh"
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/buildpspp.sh"
