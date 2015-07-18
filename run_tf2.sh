#!/bin/bash

SERVER_DIR="/srv/srcds"
ADDONS_DIR="$SERVER_DIR/tf/addons"
SM_PLUGINS_DIR="$ADDONS_DIR/sourcemod/plugins"
TEMPUS_SM_PLUGINS_DIR="$SM_PLUGINS_DIR/tempus-sourcemod-plugins"
CUSTOM_DIR = "$SERVER_DIR/tf/custom"
TEMPUS_CUSTOM_DIR="$CUSTOM_DIR/tempus"
MAPS_DIR="$TEMPUS_CUSTOM_DIR/maps"

cd ~/steamcmd
./steamcmd.sh +runscript update_tf2.txt

cd $SERVER_DIR
goh -afi -sc ./tf metamod sourcemod stripper tf2items accelerator steamtools

if [ ! -d $MAPS_DIR ]; then
    mkdir -p $MAPS_DIR
fi
cd $MAPS_DIR
~/bin/map_updater.sh

if [ ! -d $TEMPUS_SM_PLUGINS_DIR ]; then
    mkdir $TEMPUS_SM_PLUGINS_DIR
    git clone https://bitbucket.org/jsza/tempus-sourcemod-plugins.git $TEMPUS_SM_PLUGINS_DIR
fi

if [ ! -d "$CUSTOM_DIR/tf_disable_teleporters" ]
then
    mkdir "$CUSTOM_DIR/tf_disable_teleporters"
    git clone https://bitbucket.org/tempusinc/tf_disable_teleporters.git "$CUSTOM_DIR/tf_disable_teleporters"
# else
#     cd "$CUSTOM_DIR/tf_disable_teleporters"
#     git pull
fi

cd $TEMPUS_SM_PLUGINS_DIR
git pull
ln -f plugins/*.smx $SM_PLUGINS_DIR
ln -f gamedata/* "$ADDONS_DIR/sourcemod/gamedata"

if [ ! -f "$SM_PLUGINS_DIR/updater.smx" ]; then
    wget "https://bitbucket.org/GoD_Tony/updater/downloads/updater.smx" -P "$SM_PLUGINS_DIR"
fi

cd $SERVER_DIR
exec ./srcds_run -game tf $@
