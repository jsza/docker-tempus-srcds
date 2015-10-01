#!/bin/bash

SERVER_DIR="/srv/srcds"
ADDONS_DIR="$SERVER_DIR/tf/addons"
SM_PLUGINS_DIR="$ADDONS_DIR/sourcemod/plugins"
TEMPUS_SM_PLUGINS_DIR="$SM_PLUGINS_DIR/disabled/tempus-sourcemod-plugins"
CUSTOM_DIR="$SERVER_DIR/tf/custom"
TEMPUS_CUSTOM_DIR="$CUSTOM_DIR/tempus"
MAPS_DIR="$TEMPUS_CUSTOM_DIR/maps"
SP_PLUGINS_DIR="$ADDONS_DIR/source-python/plugins"

cd ~/steamcmd
./steamcmd.sh +runscript update_tf2.txt

/srv/update_tempus.py

cd $SERVER_DIR
goh -afi -sc ./tf metamod sourcemod stripper tf2items accelerator steamtools

if [ ! -d $MAPS_DIR ]; then
    mkdir -p $MAPS_DIR
fi

if [ ! -d $TEMPUS_SM_PLUGINS_DIR ]; then
    mkdir $TEMPUS_SM_PLUGINS_DIR
    git clone https://bitbucket.org/jsza/tempus-sourcemod-plugins.git $TEMPUS_SM_PLUGINS_DIR
fi

cd $TEMPUS_SM_PLUGINS_DIR
git pull
ln -f plugins/*.smx $SM_PLUGINS_DIR
ln -f gamedata/* "$ADDONS_DIR/sourcemod/gamedata"

if [ ! -f "$SM_PLUGINS_DIR/updater.smx" ]; then
    wget "https://bitbucket.org/GoD_Tony/updater/downloads/updater.smx" -P "$SM_PLUGINS_DIR"
fi

if [ ! -d "$CUSTOM_DIR/tf_disable_teleporters" ]
then
    mkdir "$CUSTOM_DIR/tf_disable_teleporters"
    git clone https://bitbucket.org/tempusinc/tf_disable_teleporters.git "$CUSTOM_DIR/tf_disable_teleporters"
else
    cd "$CUSTOM_DIR/tf_disable_teleporters"
    git pull
fi

if [ ! -d "$SP_PLUGINS_DIR/noshake" ]
then
    git clone https://bitbucket.org/Rob123/no-shake.git "$SP_PLUGINS_DIR/noshake"
elif [ ! -d "$SP_PLUGINS_DIR/noshake/.git" ]
then
    rm -r "$SP_PLUGINS_DIR/noshake"
    git clone https://bitbucket.org/Rob123/no-shake.git "$SP_PLUGINS_DIR/noshake"
else
    cd "$SP_PLUGINS_DIR/noshake"
    git pull
fi

while [ ! -f "$MAPS_DIR/tempus_map_updater_run_once" ]
do
    echo "Map updater has not completed. Retrying in 10 seconds..."
    sleep 10
done

cd $SERVER_DIR
exec ./srcds_run -game tf $@
