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

$RESOLUTION=100;


$cwd=getcwd();
chdir($BASEDIR) or die "Could not find $BASEDIR:$!\n";
$ifile = $cwd . '/' . $opt_d . '.txt';
$fl=`find . -iname \\\*.pdf | grep -v /Thumbs/ | sort > $ifile`;
$fl=`find . -iname \\\*.jpg | grep -v /Thumbs/ | sort >> $ifile`;
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
    my $pfile="$BASEDIR/$dirname/$filename";
    my $ofile="$tdir/$ofname";
    my $siz=0;
    if ( -f $ofile ) {
	$siz=(-s $ofile)
    }
    unless ( $siz ) {
	`$touch $ofile`;
	unless ($filename =~ /\.jpg$/i) {
	    `pdftotext  -q \"$pfile\" \"$ofile\"`;
	    $a=1;
	} else {
	    `gocr \"$pfile" > \"$ofile\"`;
	}
    }
    $siz=(-s $ofile);
    my $ok=($siz * ($siz - 4));
    if ($ok) {
	my $tfh;
	open($tfh,"<",$ofile) or die "Could not open $ofile: $!\n";
	my $rdtext;
	my $rc=read($tfh,$rdtext,1024,0);
	$ok=0;
	if (defined($rc)) {
	    if (defined($rdtext)) {
		if ($rdtext) {
		    unless ($rdtext =~ m/\A\s*\Z/m) {
			$ok=1;
		    }
		}
	    }
	}
    }
    unless ( $ok || 1 ) {
	print "Doing it the hard way for $pfile...";
	unlink($ofile);
	my $ENDPAGE=`pdfinfo -meta \"$pfile\" | \
                            grep ^Pages | cut -d : -f 2 | sed -e 's/\s//g'`;
	chomp $ENDPAGE;
	$ENDPAGE=$ENDPAGE-1;
	my $tif="$tdir/o.tif";
	my $ptxt="$tdir/o";
	`touch \"$ofile\"`;
	my $i;
	for ($i=0; $i < $ENDPAGE ; $i++) {
	    my $cmd="convert -monochrome -density $RESOLUTION";
	    $cmd .= " \"$pfile\"\[$i\]";
	    $cmd .= " \"$tif\"; tesseract \"$tif\" \"$ptxt\" && ";
	    $cmd .= " cat \"${ptxt}.txt\" >> \"${ofile}\"";
	    print("Running $cmd\n");
	    system($cmd);
	}
	unlink($tif);
	unlink("${ptxt}.txt");
    }
    unless (( -f $ofile) and ( -s $ofile)) {
	`echo \"Could not OCR text\" >> \"$ofile\"`;
    }
}
close INPUT;
unlink($ifile);
exit 0;

