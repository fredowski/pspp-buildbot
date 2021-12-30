# GNU PSPP buildbot

The buildbot for continuous integration for the [GNU PSPP](https://www.gnu.org/software/pspp) project is running at

https://caeis.etech.fh-augsburg.de/buildbot

The server builds the pspp sofware for

* debian-buster from [pspp git repository](https://git.savannah.gnu.org/cgit/pspp.git)
* opensuse 15.2 from [pspp distribution nightly](https://benpfaff.org/~blp/pspp-master/latest/x86_64/)
* windows cross build from debian bullseye amd64

and others. Downloads of nightly builds, e.g. for the windows cross build are available here:

https://caeis.etech.fh-augsburg.de/downloads

### Technology

The buildbot is based on 

* https://www.debian.org/releases/buster/
* http://buildbot.net
* https://wiki.debian.org/LXC
* https://libvirt.org

The builds are run in LXC containers which are created once and then copied and thrown away for each build.

### LXC Container creation

* create_debian.sh buster amd64 - Create the debian-buster build machine container
* create_suse_vm.sh - Create the opensuse 15.2 container

During creation the container setup is taken from

* lxc-config

The container is created as unpriviliged user container which is run from buildbot user.
The container is configured with a normal user "pspp" and the build is done under
this pspp account. As with travis the pspp user can do sudo. After creation
the container can be listed with

```
(sandbox) buildbot@caeis:~$ lxc-ls
debian-buster opensuse debian-buster-run
```

In the example above the two containers "debian-buster" and "opensuse" are the template
containers which have been created. The container "debian-buster-run" is a copy of "debian-buster" which
is only alive during a build. So if this container exists, a build is running.

Information about the container can be retrieved with

```
(sandbox) buildbot@caeis:~$ lxc-info -n debian-buster
Name:           debian-buster
State:          STOPPED
(sandbox) buildbot@caeis:~$ lxc-info -n debian-buster-run
Name:           debian-buster-run
State:          RUNNING
PID:            16514
IP:             192.168.122.164
Memory use:     553.84 MiB
KMem use:       47.26 MiB
Link:           vethC4GQ18
 TX bytes:      301.74 KiB
 RX bytes:      40.59 MiB
 Total bytes:   40.88 MiB
(sandbox) buildbot@caeis:~$ 
```

In the example above the container debian-buster is the source container. Container "debian-buster-run" is the
build container which is currently running and doing a build for debian-buster.

### Building pspp in a container

For each build a container, e.g. debian-buster-run,  is copied from the template container, e.g. debian-buster, and started. After
the build is finished the build container is destroyed. The build steps are defined in

* master/master.cfg

in the BUILDERS section. You can also start the build by hand with

* run_debian.sh buster amd64 for the debian buster build
* run_suse.sh for the opensuse build

Please note that the run_xxx.sh script does not stop and destroy the build container. You can
stop and destroy a build container with

```
lxc-stop -n debian-buster-run
lxc-destroy -n debian-buster-run
```

where debian-buster-run is the container name.

## Startup buildbot as service

The LXC container run requires to use systemd-run in a user context. I did not manage to start
buildbot as a system service so I run buildbot as a systemd user service. The user service file
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

You can list the currently running user services with

```
systemctl --user
```

The service calls the script "start_buildbot.sh" which actually starts
the buildbot server. To start the buildbot server at boot time you need
to enable linger for the buildbot user account. That will keep services running
and start after boot.

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
