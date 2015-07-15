$HOME/steamcmd/steamcmd.sh +runscript update_tf2.txt
cd $HOME/steamcmd/tf2
./srcds_run -game tf -steam_dir ~/steamcmd $@
