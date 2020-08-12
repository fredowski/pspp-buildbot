#!/bin/bash -xve

# Start buildbot service

PATH=/usr/local/bin:/usr/bin:/bin
source $HOME/sandbox/bin/activate
cd $HOME/pspp-buildbot
buildbot start master
buildbot-worker start --nodaemon worker

