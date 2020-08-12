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

# Install buildbot

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
