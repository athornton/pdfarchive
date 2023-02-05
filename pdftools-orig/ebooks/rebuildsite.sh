#!/bin/bash

BASEURL=http://ebooks.fsf.net/pdf
BASEDIR=/srv/www/ebooks/html/pdf
COLS=5
DIRCOLS=3
WIDTH=150

./makethumbs.pl -u $BASEURL -b $BASEDIR -d .
./maketext.pl -u $BASEURL -b $BASEDIR -d .
./makeindex.pl -u $BASEURL -b $BASEDIR -d . -c $COLS -i $DIRCOLS -w $WIDTH
swish-e -c /etc/swish-e/ebooks.conf
mv ebooks.index ebooks.index.prop /var/cache/swish-e
