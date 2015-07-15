#!/bin/bash
cd ~/steamcmd
./steamcmd.sh +runscript update_tf2.txt
cd /srv/srcds
goh . -fi -sc metamod sourcemod stripper tf2items accelerator steamtools
exec ./srcds_run -game tf -steam_dir ~/steamcmd $@
