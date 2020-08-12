# GNU PSPP buildbot

The buildbot for continuous integration for the [GNU PSPP](https://www.gnu.org/software/pspp) project is running at

http://caeis.etech.fh-augsburg.de:8010

The server builds the pspp sofware for

* debian-buster from [pspp git repository](https://git.savannah.gnu.org/cgit/pspp.git)
* opensuse 15.2 from [pspp distribution nightly](https://benpfaff.org/~blp/pspp-master/latest/x86_64/)

### Technology

The buildbot is based on 

* https://www.debian.org/releases/buster/
* http://buildbot.net
* https://wiki.debian.org/LXC
* https://libvirt.org

The builds are run in LXC containers which are created once and then copied and thrown away for each build.

### LXC Container creation

* create_lxc_vm.sh - Create the debian-buster build machine
* create_suse_vm.sh - Create the opensuse 15.2 virtual machine

During creation the vm setup is taken from

* lxc-config

The container are created as unpriviliged user containers which are run from buildbot user.

### Building pspp in a container

For each build the lxc container is copied from the source container and started. After
the build is finished the container is destroyed. The build steps are defined in

* master/master.cfg

in the BUILDERS section. You can also start the build by hand with

* run_lxc.sh for the debian buster build
* run_suse.sh for the opensuse build

## Startup buildbot as service

The LXC container run requires to use systemd-run in a user context. I did not manage to start
buildbot as a system service so I run buildbot as a user service. The user service file
"buildbot.service" must be located in "/home/buildbot/.config/systemd/user". 

```
cd
mkdir -p .config/systemd/user
pushd .config/systemd/user
ln -s ~/pspp-buildbot/buildbot.service .
popd
```

To manage the service you can

```
systemctl --user daemon-reload
systemctl --user start buildbot
systemctl --user stop buildbot
systemctl --user enable buildbot
```

The service calls the script "start_buildbot.sh" which actually starts
the buildbot server. To start the buildbot server at boot time you need
to enable linger for the buildbot account.

```
loginctl user-status buildbot
loginctl enable-linger buildbot
loginctl user-status buildbot
```

You should see something like

```
buildbot (1001)
           Since: Wed 2020-08-12 10:28:03 CEST; 51min ago
           State: active
        Sessions: 3 *2
          Linger: yes
            Unit: user-1001.slice
            ...
```





