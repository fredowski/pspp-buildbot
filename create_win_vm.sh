#!/bin/bash -xve
# Cross building for windows
# with the new build scheme from John
# Create the build machine

# Copyright (C) 2021 Free Software Foundation, Inc.
# Released under GNU General Public License, either version 3
# or any later option

distribution=debian
release=trixie
architecture=amd64

name="windows"
echo "Creating: $name"

lxc-create -n $name -t download -f lxc-config -- -d $distribution -r $release -a $architecture
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
        mingw-w64 meson ninja-build \
        imagemagick wget nsis texlive-plain-generic
# download build dependencies
lxc-unpriv-attach -n $name -- su pspp -c 'cd; wget https://cgit.git.savannah.gnu.org/cgit/pspp.git/plain/Windows/build-dependencies?id=fbb8730ed1ae86a545632cb396018edeb67a5617 -O build-dependencies'
lxc-unpriv-attach -n $name -- su pspp -c 'chmod a+x /home/pspp/build-dependencies'
lxc-unpriv-attach -n $name -- su pspp -c 'cd; ./build-dependencies --arch=x86_64-w64-mingw32 --sandbox=/home/pspp/sandbox --no-clean'
# delete all sandbox directories except the tarballs directory
lxc-unpriv-attach -n $name -- su pspp -c 'rm -rf /home/pspp/sandbox/Install;rm -rf /home/pspp/sandbox/Build;rm -rf /home/pspp/sandbox/Source'
lxc-stop $name

