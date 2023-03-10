#!/usr/bin/perl
use File::Path;
use Getopt::Std;
use Cwd;

getopts('hb:d:u:');

unless ($opt_b && $opt_d) {
    $opt_h = 1;
}

if ($opt_h) {
    print STDERR "$0 -b basedir -d subdir -u baseurl [-h]\n";
    exit 1;
}

$BASEDIR=$opt_b . '/' . $opt_d;
$BASEURL=$opt_u . '/' . $opt_d;

$cwd=getcwd();
chdir($BASEDIR) or die "Could not find $BASEDIR:$!\n";
$ifile = $cwd . '/' . $opt_d . '.txt';
$fl=`find . -iname \\\*.pdf | sort > $ifile`;
$fl=`find . -iname \\\*.jpg | grep -v '/Thumbs/' | sort >> $ifile`;
chdir($cwd);

open(INPUT,"<$ifile") or die("Could not open $ifile: $!\n");

while(<INPUT>) {
    chomp;
    s/^$BASEDIR//;
    s/^.\///;
    $ls=rindex($_,'/');

    if ($ls != -1) {
	$dirname = substr($_,0,$ls);
	$filename = substr($_,($ls + 1));
    } else {
	$filename = $_;
	$dirname = ".";
    }
    $tdir = $BASEDIR . '/Thumbs/' . $dirname;
    mkpath($tdir,{verbose => 1});
    
    $ofname = substr($filename,0,(length($filename) - 4)) . '.jpg';
    $ifname = $filename . '[0]';
    unless ( -f "$tdir/$ofname") {
	`convert \"$BASEDIR/$dirname/$ifname\" -geometry 150x100 \"$tdir/$ofname\"`;
	unless ( -f "$tdir/$ofname") {
	    `convert -size 150x100 caption:"No preview image available" -fill blue "$tdir/$ofname"`;
	}
    }
}
close INPUT;
unlink($ifile);
exit 0;
