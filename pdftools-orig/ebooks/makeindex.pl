#!/usr/bin/perl
use Cwd;
use Getopt::Std;

getopts('hb:d:u:c:i:w:');

unless ($opt_b && $opt_d) {
    $opt_h = 1;
}

if ($opt_h) {
    print STDERR "$0 -b basedir -d subdir -u baseurl [-c cols] [-i dircols] [-w width] [-h]\n";
    exit 1;
}

if ($opt_c) {
    $cols=$opt_c;
} else {
    $cols=3;
}
if ($opt_i) {
    $dircols=$opt_i;
} else {
    $dircols=2;
}
if ($opt_w) {
    $width=$opt_w;
} else {
    $width=90;
}

$BASEDIR=$opt_b;
$BASEURL=$opt_u;
if ($opt_d && $opt_d != ".") {
    $BASEDIR .= "/" . $opt_d;
    $BASEURL .= "/" . $opt_d;
}
    

chdir($BASEDIR) or die "$BASEDIR does not exist!";
blortit($BASEDIR);
exit 0;

sub blortit {
    my $newdir = shift;
    my @d = ();
    my @f = ();
    chdir($newdir);
    my $d = getcwd();
    print STDERR "Executing in $d...\n";
    my $u=$d;
    $u =~ s/^$BASEDIR/$BASEURL/;
    $u=substr($u,0,1 + rindex($u,'/'));
    print STDERR "U=$u\n";

    my $reldir = $d;
    if (($d ne $BASEDIR) and ($d ne ".")) {
	$reldir =~ s/^$BASEDIR\///;
    } else {
	$reldir = "";
    }
    print STDERR "RELDIR=$reldir\n";

    my $title = "EBooks PDFs";

    if (($d ne ".") && ($d ne $BASEDIR)) {
	$title = substr($d,rindex($d,'/')+1);
    }

    open (OUTPUT,">index.html") or die;
    select OUTPUT;

    print <<EOF;
<html>
<head>
<title>
$title
</title>
</head>
<body>
<h1>
$title
</h1>
<h2>
Search Text
</h2>
<a href="/cgi-bin/search-ebooks.cgi">Search for text in Ebooks collection</a>
<p>
<a href="$u">Enclosing directory</a>
<p>
<table cols=$cols>
EOF
;

    for $j (<*>) {
	if (-d $j) {
	    push(@d,$j);
	}
	if (-f $j) {
	    push(@f,$j);
	}
    }

    $i=0;
    for (@f) {
	next unless (/\.pdf$/);
	$i++;
	$filename = $_;
	s/#/%23/;
	s/ /%20/;
	$tn=substr($filename,0,(length($filename)-4));
	$thumb = $tn . ".jpg";
	$textname = $tn . ".txt";
	$textname =~ s/#/%23/;
	$textname =~ s/ /%20/;
	$thumb =~ s/#/%23/;
	$thumb =~ s/ /%20/;
	if ($i==1) {    
	    print "<tr>\n";
	}
	print "<td>\n";
	$tw=int($width/$cols);
	$tn = substr($tn,0,$tw);
	$pad = "";
	$ptl=length($tn);
	if ($ptl < $tw) {
	    for ($k=$ptl;$k<$tw;$k++) {
		$pad .= "&nbsp;";
	    }
	}
	$textlink = $BASEURL . "/Text/";
	if ($reldir) {
	    $textlink .= "$reldir/";
	}
	$textlink .= "$textname";
	print "<a href=\"./$_\"><img src=\"$BASEURL/Thumbs/";
	if ($reldir) { 
	    print "$reldir/";
	}
	print "$thumb\" alt=\"[$tn]\" title=\"[$tn]\"><br>$tn</a>$pad<br>\n";
	print "<a href=\"$textlink\">[text]</a>\n";
	print "</td>\n";
	if ($i==$cols) {
	    print "</tr>\n";
	    $i=0;
	}
    }
    if ($i) {
	print "</tr>\n";
    }
    print "</table>\n";
    print "<hr>\n";
    print "<table cols=$dircols>\n";
    $i=0;
    for (@d) {
	next if ((/^Text$/) or (/^Thumbs$/));
	$i++;
	chomp;
	$filename = $_;
	if ($i==1) {    
	    print "<tr>\n";
	}
	print "<td>\n";
	$tn = $_;
	$tw=($width/$dircols);
	$tn = substr($tn,0,$tw);
	$ptn=$tn;
	$ptl=length($ptn);
	$pad = "";
	$ptl=length($ptn);
	if ($ptl < $tw) {
	    for ($k=$ptl;$k<$tw;$k++) {
		$pad .= "&nbsp;";
	    }
	}
	print "<a href=\"$_\"><img src=\"$BASEURL/Thumbs/folder.png\" alt=\"\[$tn\]\" title=\"[$tn]\">$tn</a>$pad<p>\n";
	print "</td>\n";
	if ($i==$dircols) {
	    print "</tr>\n";
	    $i=0;
	}
}

    print <<EOF;
</table>
</body>
</html>
EOF
;

    close (OUTPUT);

    for (@d) {
	next if ((/^Text$/) or (/^Thumbs$/));
	$dir = $d . "/" . $_;
	print STDERR "Recursing: calling blortit() on $dir\n";
	blortit($dir);
    }
}
