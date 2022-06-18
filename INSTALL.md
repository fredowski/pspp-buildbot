# GNU PSPP buildbot server installation

The server is based on debian buster. The server is hosted at Hochschule Augsburg in a VMWare environment as virtual machine.

* 2 cores
* 4 GB RAM
* 30 GB Storage

The install of the base system is not covered here as this is specific for the
VMWare environment at Hochschule Augsburg. I assume that you have done a server
installation with "ssh server" enabled. You created a normal user account, e.g. john.
This user account is part of the sudo group. I enabled ssh login via ssh-key.

### Create user buildbot

The buildbot server and the builds are run under a new user buildbot which is a normal
user without sudo permissions.

```
sudo adduser buildbot
```

### Install buildbot

There is a debian buildbot package but I install via virtualenv in a sandbox.

```
sudo apt install python3-venv git
```

As user buildbot

```
cd
python3 -m venv sandbox
source sandbox/bin/activate
```

I added

```
# Activate python virtualenv
if [ -f "$HOME/sandbox/bin/activate" ] ; then
    source $HOME/sandbox/bin/activate
fi 
```

to the .profile for the buildbot user such that for every login
the python virtualenv sandbox is already active. Then buildbox is
installed in this virtual environment. See:

http://docs.buildbot.net/current/tutorial/firstrun.html#creating-a-master

```
pip install --upgrade pip
pip install 'buildbot[bundle]'
pip install buildbot-worker
pip install buildbot-badges
pip install setuptools-trial
```

The master and the worker is installed in the same virtualenv environment.
I install the buildbot files from the git repository.

```
cd
git clone https://github.com/fredowski/pspp-buildbot.git
cd pspp-buildbot
buildbot create-master master
buildbot-worker create-worker worker localhost hsa-worker pspp4you
```

### Install the LXC container system

The lxc containers can be run as system container from root
or as unpriviliged user containers from user buildbot. I want to start a new 
container for each build and therefore I do everything in unpriviliged
user containers. The containers must have a connection to the internet and
that is done via a libvirt bridge. That bridge has a DHCP server included such
that the containers get their IP address vom the libvirt bridge. So we have

* unprivilidged user containers run by buildbot
* a libvirt based bridge for net access

#### Cgroups V1 and V2

The lxc containers do the access control and management to devices via kernel
provided control groups (cgroup). There is a new v2 scheme and the host is
configured to use a "hybrid" system with v1 and v2 cgroups. I think the bridge
uses v1 and the lxc uses v2 - but I am not sure. Whenever there are problems
with starting the lxc containers it is probably due to some configuration
problem related to cgroups.

https://wiki.debian.org/LXC/CGroupV2

Install the packages with

```
sudo apt install lxc bridge-utils uidmap
```

##### Configure the host kernel - allow user namespaces

The kernel must be configure to allow user namespaces. This controlled via
the kernal parameter "unprivileged_userns_clone". It must be set to 1. Check
and set the parameter

```
cat /proc/sys/kernel/unprivileged_userns_clone
sysctl -w kernel.unprivileged_userns_clone=1
```

For a permanent change do:

```
sudo sh -c "echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/53-lxc-unpriv.conf"
```

### Libvirt bridge

I use the default libvirt bridge network with DHCP. Install the packages with
```
sudo apt install --no-install-recommends qemu-kvm libvirt-clients \
libvirt-daemon-system \
virtinst \
qemu-utils \
dnsmasq-base
```

Add the user buildbot to the libvirt group and increase the quota for the
number of devices that user buildbot can attach to the bridge.

```
sudo adduser buildbot libvirt
sudo sh -c "echo 'buildbot veth virbr0 10' >> /etc/lxc/lxc-usernet"
```

To start the libvirt bridge

```
virsh --connect=qemu:///system net-start default
```

You can check the status and manage the bridge with

```
(sandbox) buildbot@caeis:~/pspp-buildbot$ virsh --connect=qemu:///system net-list --all
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes

```

Destroy the bridge:
```
virsh --connect=qemu:///system net-destroy default
```

Enable the autostart of the bridge at boot

```
virsh --connect=qemu:///system net-autostart default
```

### UID and GID

When the container is run as user, then the user id (uid) and the group id (gid) must be
mapped. The buildbot user has sub user and group ids that can be used. They are defined
in 

```
(sandbox) buildbot@caeis:~$ cat /etc/subuid
buildbot:165536:65536
(sandbox) buildbot@caeis:~$ cat /etc/subgid
buildbot:165536:65536
(sandbox) buildbot@caeis:~$ 
```
These settings must match the setting in the lxc configuration file.

#### Example lxc-config file

```
# Configuration file to create lxc containers

# network
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.link = virbr0
lxc.net.0.name = eth0
lxc.net.0.ipv4.address = 0.0.0.0/24

# idmap - compare with /etc/subuid and /etc/subgid
lxc.idmap = u 0 165536 65536
lxc.idmap = g 0 165536 65536

# We must turn off the CGroup V1 device controls so that LXC can start
lxc.cgroup.devices.deny =
lxc.cgroup.devices.allow =

# If /sbin/init in guest is systemd, it requires LXC to prepare /sys/fs/cgroup
lxc.mount.auto = cgroup:rw:force

lxc.apparmor.profile = unconfined

lxc.init.cmd = /sbin/init systemd.unified_cgroup_hierarchy=1
```

#### Example session

If everything is setup, then 

```
(sandbox) buildbot@caeis:~/pspp-buildbot$ lxc-create -n debian-container  -t download -f lxc-config -- -d debian -r stretch -a amd64
Setting up the GPG keyring
Downloading the image index
Downloading the rootfs
Downloading the metadata
The image cache is now ready
Unpacking the rootfs

---
You just created a Debian stretch amd64 (20200812_05:24) container.

To enable SSH, run: apt install openssh-server
No default root or user password are set by LXC.
(sandbox) buildbot@caeis:~/pspp-buildbot$ lxc-ls
debian-buster    debian-container opensuse         
(sandbox) buildbot@caeis:~/pspp-buildbot$ lxc-info debian-container
Name:           debian-container
State:          STOPPED
(sandbox) buildbot@caeis:~/pspp-buildbot$ systemd-run --user -p "Delegate=yes" lxc-start -F debian-container
Running as unit: run-r36f4233c31a042deaaec3fa7af01124a.service
(sandbox) buildbot@caeis:~/pspp-buildbot$ lxc-info debian-container
Name:           debian-container
State:          RUNNING
PID:            11657
IP:             192.168.122.217
Memory use:     15.44 MiB
KMem use:       3.06 MiB
Link:           vethMOG2Y9
 TX bytes:      2.02 KiB
 RX bytes:      2.15 KiB
 Total bytes:   4.17 KiB
(sandbox) buildbot@caeis:~/pspp-buildbot$ lxc-attach -n debian-container
root@debian-container:/# ping -c 3 www.debian.org
PING www.debian.org (130.89.148.77) 56(84) bytes of data.
64 bytes from klecker-misc.debian.org (130.89.148.77): icmp_seq=1 ttl=52 time=19.0 ms
64 bytes from klecker-misc.debian.org (130.89.148.77): icmp_seq=2 ttl=52 time=19.2 ms
64 bytes from klecker-misc.debian.org (130.89.148.77): icmp_seq=3 ttl=52 time=19.1 ms

--- www.debian.org ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 19.083/19.158/19.231/0.060 ms
root@debian-container:/# exit
exit
(sandbox) buildbot@caeis:~/pspp-buildbot$
```

You created a debian stretch container, started the container, logged in and you
run ping as root.
