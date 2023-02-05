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

$RESOLUTION=300;


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
    
    $basename = substr($filename,0,(length($filename) - 4));
    $ofname = $basename . '.txt';
    my $pfile="$BASEDIR/$dirname/$filename";
    my $ofile="$tdir/$ofname";
    my $siz=0;
    if ( -f $ofile ) {
	$siz=(-s $ofile)
    }
    unless ( $siz ) {
	`$touch \'$ofile\'`;
	unless ($filename =~ /\.jpg$/i) {
	    `pdftotext  -q \'$pfile\' \'$ofile\'`;
	    $a=1;
	} else {
	    `gocr \'$pfile\' > \'$ofile\'`;
	}
    }
    $siz=(-s $ofile);
    my $ok=($siz * ($siz - 4));
    if ($ok) {
	my $tfh;
	open($tfh,"<",$ofile) or die "Could not open \'$ofile\': $!\n";
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
    unless ( $ok ) {
	print "Doing it the hard way for $pfile...\n";
	unlink($ofile);
	my $tif="$tdir/$basename.tif";	
	my $cmd1="convert -density $RESOLUTION ";
	$cmd1 .= "\'$pfile\' -depth 8 -strip -background white ";
	$cmd1 .= "-alpha off -monitor -debug cache \'$tif\'";
	$cmd2 = "tesseract \'$tif\' \'$tdir/$basename\'";
	$cmd3 = "mv \'$tdir/$basename.txt\' \'${ofile}\'";
	print("Cmd 1: $cmd1\n");
	system($cmd1);
	print("Cmd 2: $cmd2\n");
	system($cmd2);
	print("Cmd 3: $cmd3\n");
	system($cmd3);
	unlink($tif);
    }
    unless (( -f $ofile) and ( -s $ofile)) {
	`echo \"Could not OCR text\" >> \"$ofile\"`;
    }
}
close INPUT;
unlink($ifile);
exit 0;

