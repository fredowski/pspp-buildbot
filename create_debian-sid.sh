#!/bin/bash -xve

distribution=debian
release=sid

name="$distribution-$release"

lxc-create -n $name -t download -f lxc-config -- -d $distribution -r $release -a amd64
systemd-run --user -p "Delegate=yes" lxc-start -F $name
# wait for network
sleep 15
lxc-attach -n $name -- apt install -y openssl openssh-server sudo
lxc-attach -n $name -- /usr/sbin/useradd -s /bin/bash -m -p $(openssl passwd -1 pspp4you) pspp
lxc-attach -n $name -- sh -c "echo 'pspp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
# pspp
lxc-attach -n $name -- apt install -y build-essential python3 perl texinfo texlive \
        libgsl-dev libgtk-3-dev libgtksourceview-3.0-dev \
        pkg-config gimp gperf git zip curl autoconf libtool \
        gettext libreadline-dev
lxc-stop $name

