#!/bin/sh
if [ -f index.html ]
then
        rm index.html
fi

wget --no-remove-listing http://tempus.site.nfoservers.com/server/maps/
if [ -f allmaps.txt ]
then
        rm allmaps.txt
fi
awk 'BEGIN{ RS="<a *href *= *\""} NR>2 {sub(/".*/,"");print; }' index.html >> converted.txt
grep '.bsp' converted.txt | awk -F".bz2" '{print $1}' >> allmaps.txt
for line in $(cat allmaps.txt)
do
        if [ ! -f $line ]
        then
                echo "Unable to find $line. Downloading..."
                wget http://tempus.site.nfoservers.com/server/maps/$line.bz2
                bzip2 -d $line.bz2
        fi
done

default="$HOME/bin/default_level_sounds.txt"
for file in *.bsp
do
        map="${file%.*}_level_sounds.txt"
        if [ ! -f $map ]
        then
                echo "Creating $map..."
                cp $default $map
        fi
done
echo "Finished creating level sounds. Now cleaning up"

for file2 in *level_sounds.txt
do
        text="${file2%_level_sounds.txt}.bsp"
        if [ ! -f $text ]
        then
        if [ "$file2" != "default_level_sounds.txt" ]
        then
                echo "Can't find $text, removing $file2"
                rm $file2
        fi
        fi
done

rm converted.txt
rm index.html
