#!/bin/bash -xve

name="opensuse"
newname="vm2"

lxc-info $name
lxc-copy --name $name --newname vm2
systemd-run --user -p "Delegate=yes" lxc-start -F vm2
# Wait for container to be RUNNING (better than blind sleep)
echo "Waiting for vm2 to start..."
for i in $(seq 1 30); do
    state=$(lxc-info -n "vm2" | awk '/State:/{print $2}')
    [ "$state" = "RUNNING" ] && break
    sleep 1
done
if [ "$state" != "RUNNING" ]; then
    echo "ERROR: vm2 failed to start"
    exit 1
fi
# Wait for network (ping internal gateway or check with lxc-attach)
echo "Waiting for network..."
for i in $(seq 1 30); do
    lxc-attach -n "vm2" -- ping -c1 -W1 8.8.8.8 &>/dev/null && break
    sleep 1
done

# Copy the files in directory ./ci into the container
pushd ~/pspp-buildbot
tar -c ./ci | lxc-attach -n vm2 -- sh -c 'trap "" HUP;tar -C /home/pspp -x'
popd
#lxc-attach -n vm2 -- su pspp -c "cd; ./ci/prepare.sh"
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/buildssw.sh"
lxc-attach -n vm2 -- su pspp -c "cd; ./ci/buildpspp.sh"
