#!/bin/bash

SERVER_DIR="/srv/srcds"
ADDONS_DIR="$SERVER_DIR/tf/addons"
SM_PLUGINS_DIR="$ADDONS_DIR/sourcemod/plugins"
TEMPUS_SM_PLUGINS_DIR="$SM_PLUGINS_DIR/tempus-sourcemod-plugins")

cd ~/steamcmd
./steamcmd.sh +runscript update_tf2.txt

if [ ! -d $TEMPUS_SM_PLUGINS_DIR ]; then
    mkdir $TEMPUS_SM_PLUGINS_DIR
    git clone git@bitbucket.org:jsza/tempus-sourcemod-plugins.git $TEMPUS_SM_PLUGINS_DIR
fi

cd $TEMPUS_SM_PLUGINS_DIR
git pull

cd $SERVER_DIR
goh -afi -sc ./tf metamod sourcemod stripper tf2items accelerator steamtools
exec ./srcds_run -game tf $@
