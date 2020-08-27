#!/bin/bash -xve

name="windows"
newname="windows-run"

lxc-info $name
lxc-copy --name $name --newname $newname
systemd-run --user -p "Delegate=yes" lxc-start -F $newname
# Wait for network to be ready
sleep 15
# Copy the files in directory ./ci into the container
pushd ~/pspp-buildbot
tar -c ./win | lxc-attach -n $newname -- tar -C /home/pspp -vx
popd
lxc-attach -n $newname -- su pspp -c "cd; sudo chown -R pspp:users ./win"
lxc-attach -n $newname -- su pspp -c "cd ~/win; ./buildssw-win.sh"

lxc-attach -n $newname -- su pspp -c "cd ~/win; ./buildpspp4windows.pl"

