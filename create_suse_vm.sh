#!/bin/bash -xve

name="opensuse"

lxc-create -n $name -t download -f lxc-config -- --keyserver keyserver.ubuntu.com -d opensuse -r tumbleweed -a amd64
systemd-run --user -p "Delegate=yes" lxc-start -F $name
# wait for network
sleep 15
lxc-unpriv-attach -n $name -- zypper install -y openssl openssh sudo
lxc-unpriv-attach -n $name -- /usr/sbin/useradd -s /bin/bash -m -p $(openssl passwd -1 pspp4you) pspp
lxc-unpriv-attach -n $name -- sh -c "echo 'pspp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
lxc-unpriv-attach -n $name -- sh -c "echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config"
lxc-unpriv-attach -n $name -- su pspp -c 'chmod a+rx ~'
lxc-unpriv-attach -n $name -- su pspp -c 'mkdir ~/.ssh'
cat buildbot_rsa.pub | lxc-unpriv-attach -n $name -- /bin/bash -c "/bin/cat > /home/pspp/.ssh/authorized_keys"
# pspp
lxc-unpriv-attach -n $name -- zypper install -y gcc python3 perl texinfo texlive \
        gsl-devel gtk3-devel gtksourceview4-devel \
        pkg-config gperf git unzip curl autoconf libtool \
        texlive-wasy \
        readline-devel libxml2-devel automake make \
        glibc-locale AppStream-devel
lxc-stop $name

