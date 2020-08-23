#!/bin/bash

SERVER_DIR="/srv/srcds"
ADDONS_DIR="$SERVER_DIR/tf/addons"
SM_PLUGINS_DIR="$ADDONS_DIR/sourcemod/plugins"
TEMPUS_SM_PLUGINS_REPO_DIR="$SM_PLUGINS_DIR/disabled/tempus-sourcemod-plugins"
TEMPUS_SM_PLUGINS_DIR="$SM_PLUGINS_DIR/tempus_plugins"
CUSTOM_DIR="$SERVER_DIR/tf/custom"
TEMPUS_CUSTOM_DIR="$CUSTOM_DIR/tempus"
MAPS_DIR="$TEMPUS_CUSTOM_DIR/maps"
SP_PLUGINS_DIR="$ADDONS_DIR/source-python/plugins"

cd ~/steamcmd
./steamcmd.sh +runscript update_tf2.txt

/venv/bin/python /srv/update_tempus.py

cd $SERVER_DIR
/venv/bin/goh --allow-full-install --skip-confirm ./tf metamod sourcemod stripper tf2items accelerator steamtools collisionhook dhooks

rm -f "$SM_PLUGINS_DIR/nextmap.smx"
rm -f "$SM_PLUGINS_DIR/basetriggers.smx"

if [ ! -d $MAPS_DIR ]; then
    mkdir -p $MAPS_DIR
fi

if [ ! -d $TEMPUS_SM_PLUGINS_REPO_DIR ]; then
    mkdir $TEMPUS_SM_PLUGINS_REPO_DIR
    git clone https://bitbucket.org/jsza/tempus-sourcemod-plugins.git $TEMPUS_SM_PLUGINS_REPO_DIR
fi

cd $TEMPUS_SM_PLUGINS_REPO_DIR
git pull
ln --symbolic --force --no-target-directory "$TEMPUS_SM_PLUGINS_REPO_DIR/plugins/" $TEMPUS_SM_PLUGINS_DIR

for filename in plugins/*.smx; do
    rm -f "$SM_PLUGINS_DIR/$(basename $filename)"
done

if [ -d $TEMPUS_SM_PLUGINS_REPO_DIR/gamedata ]; then
    ln --symbolic --force $TEMPUS_SM_PLUGINS_REPO_DIR/gamedata/* "$ADDONS_DIR/sourcemod/gamedata"
fi

if [ ! -f "$SM_PLUGINS_DIR/updater.smx" ]; then
    wget "https://bitbucket.org/jsza/tempus-sourcemod-plugins/downloads/updater.smx" -P "$SM_PLUGINS_DIR"
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
exec ./srcds_run -game tf -debug $@
