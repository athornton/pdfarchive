#!/bin/bash

BASEURL=http://bloomcounty.fsf.net
BASEDIR=/srv/www/bloomcounty/html
COLS=5
DIRCOLS=3
WIDTH=150

./makethumbs.pl -u $BASEURL -b $BASEDIR -d .
./maketext.pl -u $BASEURL -b $BASEDIR -d .
./makeindex.pl -u $BASEURL -b $BASEDIR -d . -c $COLS -i $DIRCOLS -w $WIDTH
swish-e -c /etc/swish-e/bloomcounty.conf
mv bloomcounty.index bloomcounty.index.prop /var/cache/swish-e
