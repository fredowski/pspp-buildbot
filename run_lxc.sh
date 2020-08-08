#!/bin/bash -xve

name="debian-buster"

lxc-copy --name $name --newname vm1
lxc-start vm1 --logfile=/tmp/lxc.log --logpriority=INFO
sleep 15
lxc-attach -n vm1 -- su pspp -c "cd; git clone https://github.com/fredowski/pspp.git"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; git checkout travis"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; ./ci/prepare.sh"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; ./ci/buildssw.sh"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; make -f Smake"
lxc-attach -n vm1 -- su pspp -c "cd ~/pspp; ./ci/buildpspp-linux.sh"
