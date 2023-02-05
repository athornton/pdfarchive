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
$fl=`find . -name \\\*.pdf | sort > $ifile`;
chdir($cwd);

open(INPUT,"<$ifile") or die("Could not open $ifile: $!\n");

while(<INPUT>) {
    chomp;
    s/^.\///;
#    s/'/\\'/g;

    $ls=rindex($_,'/');

    if ($ls != -1) {
	$dirname = substr($_,0,$ls);
	$filename = substr($_,($ls + 1));
    } else {
	$dirname = "";
	$filename = $_;
    }
    

    $tdir = $BASEDIR . '/Text/' . $dirname;

    mkpath($tdir,{verbose => 1});
    
    $ofname = substr($filename,0,(length($filename) - 4)) . '.txt';


    unless ( -f "$tdir/$ofname") {
	`pdftotext  -q \"$BASEDIR/$dirname/$filename\" \"$tdir/$ofname\"`;
    }
}
close INPUT;
unlink($ifile);
exit 0;

