#!/bin/bash -xve

distribution=debian
release=$1
architecture=$2

function usage {
  echo "usage: $0 release architecture"
  echo "release = buster or sid"
  echo "architecture = amd64 or i386"
  exit 1
}

# Check input parameters
case $release in
  buster|sid) ;;
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

lxc-info -n $name
lxc-copy --name $name --newname $buildvm
systemd-run --user -p "Delegate=yes" lxc-start -F $buildvm
sleep 15
# Copy the files in directory ./ci into the container
pushd ~/pspp-buildbot
tar -c ./ci | lxc-attach -n $buildvm -- tar -C /home/pspp -vx
popd
lxc-attach -n $buildvm -- su pspp -c "cd; git clone --depth=2 git://git.savannah.gnu.org/pspp.git"
lxc-attach -n $buildvm -- su pspp -c "cd; ./ci/prepare.sh"
lxc-attach -n $buildvm -- su pspp -c "cd; ./ci/buildssw.sh"
lxc-attach -n $buildvm -- su pspp -c "cd ~/pspp; make -f Smake"
lxc-attach -n $buildvm -- su pspp -c "cd; ./ci/buildpspp-git.sh"
