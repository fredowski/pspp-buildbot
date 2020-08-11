#!/bin/bash -xve

name="opensuse"

lxc-create -n $name -t download -f lxc-suse-config -- -d opensuse -r 15.2 -a amd64
systemd-run --user --scope -p "Delegate=yes" lxc-start $name
# wait for network
sleep 15
lxc-attach -n $name -- zypper install -y openssl openssh sudo
lxc-attach -n $name -- /usr/sbin/useradd -s /bin/bash -m -p $(openssl passwd -1 pspp4you) pspp
lxc-attach -n $name -- sh -c "echo 'pspp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
# pspp
lxc-attach -n $name -- zypper install -y gcc python3 perl texinfo texlive \
        gsl-devel gtk3-devel gtksourceview-devel \
        pkg-config gperf git unzip curl autoconf libtool \
        gettext readline-devel libxml2-devel automake make \
        glibc-locale
lxc-stop $name

