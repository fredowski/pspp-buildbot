#!/bin/bash -xve

name="debian-buster"

lxc-create -n $name -t download -f lxc-config -- -d debian -r buster -a amd64
lxc-start $name
# wait for network
sleep 15
lxc-attach -n $name -- apt install -y openssl openssh-server
lxc-attach -n $name -- /usr/sbin/useradd -s /bin/bash -m -p $(openssl passwd -1 pspp4you) pspp
# pspp
lxc-attach -n $name -- apt install -y build-essential python3 perl texinfo texlive \
        libgsl-dev libgtk-3-dev libgtksourceview-3.0-dev \
        pkg-config gimp gperf git zip curl autoconf libtool


# libvirt

