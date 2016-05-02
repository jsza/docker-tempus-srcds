FROM jayess/tempus-base

USER steam
ENV HOME /home/steam
ENV STEAMCMD $HOME/steamcmd

COPY ./update_tf2.txt $STEAMCMD/update_tf2.txt
COPY ./run_tf2.sh $STEAMCMD/run_tf2.sh
COPY ./update_tempus.py /srv/update_tempus.py

RUN $STEAMCMD/steamcmd.sh +quit

ENTRYPOINT ["/home/steam/steamcmd/run_tf2.sh"]
