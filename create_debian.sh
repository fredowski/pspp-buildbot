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
echo "Creating: $name"

export LANG=
lxc-create -n $name -t download -f lxc-config -- --keyserver keyserver.ubuntu.com -d $distribution -r trixie -a $architecture
systemd-run --user -p "Delegate=yes" lxc-start -F $name
# wait for network
sleep 15
lxc-unpriv-attach -n $name -- apt update
lxc-unpriv-attach -n $name -- apt upgrade -y
lxc-unpriv-attach -n $name -- apt install -y openssl openssh-server sudo
lxc-unpriv-attach -n $name -- /usr/sbin/useradd -s /bin/bash -m -p $(openssl passwd -1 pspp4you) pspp
lxc-unpriv-attach -n $name -- sh -c "echo 'pspp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
lxc-unpriv-attach -n $name -- sh -c "echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config"
lxc-unpriv-attach -n $name -- su pspp -c 'mkdir ~/.ssh'
cat buildbot_rsa.pub | lxc-unpriv-attach -n $name -- /bin/bash -c "/bin/cat > /home/pspp/.ssh/authorized_keys"
# pspp
lxc-unpriv-attach -n $name -- apt install -y build-essential python3 perl texinfo texlive \
        libgsl-dev libgtk-3-dev libgtksourceview-4-dev \
        pkg-config gperf git zip curl autoconf libtool \
        gettext libreadline-dev appstream \
        texlive-plain-generic librsvg2-bin \
        libtext-diff-perl
lxc-stop $name

