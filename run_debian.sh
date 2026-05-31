#!/bin/bash -xve

distribution=debian
release=$1
architecture=$2

function usage {
  echo "usage: $0 release architecture"
  echo "release = bullseye or sid"
  echo "architecture = amd64 or i386"
  exit 1
}

# Check input parameters
case $release in
  bullseye|sid) ;;
  *) usage ;;
esac

case $architecture in
  amd64|i386) ;;
  *) usage ;;
esac

name="$distribution-$release-$architecture"

buildvm="$name-build"

# Set the default file creation mode to readable for all
umask 22
export LANG=


lxc-info -n $name
lxc-copy --name $name --newname $buildvm
systemd-run --user -p "Delegate=yes" lxc-start -F $buildvm
# 5. Wait for container to be RUNNING (better than blind sleep)
echo "Waiting for $buildvm to start..."
for i in $(seq 1 30); do
    state=$(lxc-info -n "$buildvm" | awk '/State:/{print $2}')
    [ "$state" = "RUNNING" ] && break
    sleep 1
done
if [ "$state" != "RUNNING" ]; then
    echo "ERROR: $buildvm failed to start"
    exit 1
fi
# 6. Wait for network (ping internal gateway or check with lxc-attach)
echo "Waiting for network..."
for i in $(seq 1 30); do
    lxc-attach -n "$buildvm" -- ping -c1 -W1 8.8.8.8 &>/dev/null && break
    sleep 1
done

# Copy the files in directory ./ci into the container
pushd ~/pspp-buildbot
tar -c ./ci | lxc-attach -n $buildvm -- sh -c 'tar -C /home/pspp -x'
popd

pushd ~/pspp-buildbot
tar -cf /tmp/$name-gitrepo.tar --directory=worker/$name build
scp -o StrictHostKeyChecking=no \
    -i ./buildbot_rsa \
    /tmp/$name-gitrepo.tar \
    pspp@`lxc-info -n $buildvm -i -H`:~
popd

lxc-attach -n $buildvm -- /bin/bash -c "/home/pspp/ci/upgrade.sh"
lxc-attach -n $buildvm -- su pspp -c "cd; tar -xf $name-gitrepo.tar"
lxc-attach -n $buildvm -- su pspp -c "cd; mv build pspp"

#lxc-attach -n $buildvm -- su pspp -c "cd; git clone --depth=2 git://git.savannah.gnu.org/pspp.git"
lxc-attach -n $buildvm -- su pspp -c "cd; ./ci/prepare.sh"
lxc-attach -n $buildvm -- su pspp -c "cd; ./ci/buildssw.sh"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; make -f Smake"
lxc-attach -n $buildvm -- su pspp -c "cd; ./ci/buildpspp-git.sh"
