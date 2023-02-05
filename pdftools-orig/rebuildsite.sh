#!/bin/bash

BASEURL=https://rpg.fsf.net
BASEDIR=/srv/www/rpg/html
COLS=5
DIRCOLS=3
WIDTH=150

for i in Mags TSR Other; do
    ./makethumbs.pl -u $BASEURL -b $BASEDIR -d $i
    # ./maketext-boring.pl -u $BASEURL -b $BASEDIR -d $i
     ./maketext.pl -u $BASEURL -b $BASEDIR -d $i
#    ./makeindex.pl -u $BASEURL -b $BASEDIR -d $i -c $COLS -i $DIRCOLS -w $WIDTH
    ./makeindex.pl -u $BASEURL -b $BASEDIR -d $i
    swish-e -c /etc/swish-e/$i.conf 2>&1 | grep -v 'checking dir'
    mv $i.index $i.index.prop /var/cache/swish-e
done
