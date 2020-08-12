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

