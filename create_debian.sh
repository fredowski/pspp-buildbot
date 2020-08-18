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
echo "Creating: $name"

lxc-create -n $name -t download -f lxc-config -- -d $distribution -r $release -a $architecture
systemd-run --user -p "Delegate=yes" lxc-start -F $name
# wait for network
sleep 15
lxc-attach -n $name -- apt update
lxc-attach -n $name -- apt upgrade -y
lxc-attach -n $name -- apt install -y openssl openssh-server sudo
lxc-attach -n $name -- /usr/sbin/useradd -s /bin/bash -m -p $(openssl passwd -1 pspp4you) pspp
lxc-attach -n $name -- sh -c "echo 'pspp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
lxc-attach -n $name -- sh -c "echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config"
lxc-attach -n $name -- su pspp -c 'mkdir ~/.ssh'
cat buildbot_rsa.pub | lxc-attach -n $name -- /bin/bash -c "/bin/cat > /home/pspp/.ssh/authorized_keys"
# pspp
lxc-attach -n $name -- apt install -y build-essential python3 perl texinfo texlive \
        libgsl-dev libgtk-3-dev libgtksourceview-3.0-dev \
        pkg-config gimp gperf git zip curl autoconf libtool \
        gettext libreadline-dev
lxc-stop $name

