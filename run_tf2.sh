#!/bin/bash
cd ~/steamcmd
./steamcmd.sh +runscript update_tf2.txt
cd /srv/srcds
./srcds_run -game tf -steam_dir ~/steamcmd $@
