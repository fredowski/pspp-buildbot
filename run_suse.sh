#!/bin/bash -xve

name="opensuse"
newname="vm2"

lxc-copy --name $name --newname vm2
systemd-run --user --scope -p "Delegate=yes" lxc-start vm2
sleep 15

tar -c ./ci | lxc-attach -n vm2 -- tar -C /home/pspp -vx
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/prepare.sh"
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/buildssw.sh"
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/buildpspp.sh"
