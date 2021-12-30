#!/bin/bash -xve
# Cross building for windows
# with the new build scheme from John
# Create the build machine

# Copyright (C) 2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

distribution=debian
release=bullseye
architecture=amd64

name="windows"
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
        pkg-config gperf git zip curl autoconf libtool \
        gettext libreadline-dev appstream \
        mingw-w64 meson ninja-build \
        imagemagick wget nsis texlive-plain-generic
lxc-stop $name

