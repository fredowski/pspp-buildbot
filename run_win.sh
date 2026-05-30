#!/bin/bash -xve

name="windows"
newname="windows-run"

lxc-info $name
lxc-copy --name $name --newname $newname
systemd-run --user -p "Delegate=yes" lxc-start $newname
# 5. Wait for container to be RUNNING (better than blind sleep)
echo "Waiting for $newname to start..."
for i in $(seq 1 30); do
    state=$(lxc-info -n "$newname" | awk '/State:/{print $2}')
    [ "$state" = "RUNNING" ] && break
    sleep 1
done
if [ "$state" != "RUNNING" ]; then
    echo "ERROR: $newname failed to start"
    exit 1
fi
# 6. Wait for network (ping internal gateway or check with lxc-attach)
echo "Waiting for network..."
for i in $(seq 1 30); do
    lxc-attach -n "$newname" -- ping -c1 -W1 8.8.8.8 &>/dev/null && break
    sleep 1
done
# Copy the files in directory ./win into the container
pushd ~/pspp-buildbot
tar -c ./win | lxc-attach -n $newname -- tar -C /home/pspp -vx
popd
lxc-attach -n $newname -- su pspp -c "cd; sudo chown -R pspp:users ./win"
lxc-attach -n $newname -- su pspp -c "cd; ./win/buildpspp-win.sh"

