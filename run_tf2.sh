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

cd $SERVER_DIR
goh -afi -sc ./tf metamod sourcemod stripper tf2items accelerator steamtools

if [ ! -d $MAPS_DIR ]; then
    mkdir -p $MAPS_DIR
fi

while [ ! -f "$MAPS_DIR/tempus_map_updater_run_once" ]
do
    echo "Map updater has not completed. Retrying in 10 seconds..."
    sleep 10
done

cd $SERVER_DIR
exec ./srcds_run -game tf $@
