#!/bin/bash

BASEURL=http://cgw.fsf.net
BASEDIR=/srv/www/cgw/html
COLS=5
DIRCOLS=3
WIDTH=150

./makethumbs.pl -u $BASEURL -b $BASEDIR -d .
./maketext.pl -u $BASEURL -b $BASEDIR -d .
./makeindex.pl -u $BASEURL -b $BASEDIR -d . -c $COLS -i $DIRCOLS -w $WIDTH
swish-e -c /etc/swish-e/cgw.conf
mv cgw.index cgw.index.prop /var/cache/swish-e
