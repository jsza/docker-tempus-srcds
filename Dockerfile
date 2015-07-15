FROM debian:jessie

RUN dpkg --add-architecture i386
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -qy install --no-install-recommends python python-pip ca-certificates libpq5:i386 lib32gcc1 lib32tinfo5 lib32ncurses5 wget
RUN adduser --gecos "" steam

USER steam
ENV HOME /home/steam
ENV STEAMCMD $HOME/steamcmd

RUN mkdir $STEAMCMD && wget -O - http://media.steampowered.com/client/steamcmd_linux.tar.gz | tar -C $STEAMCMD -xvz

ADD ./update_tf2.txt $STEAMCMD/update_tf2.txt
ADD ./run_tf2.sh $STEAMCMD/run_tf2.sh

ENTRYPOINT ["/home/steam/steamcmd/run_tf2.sh"]
