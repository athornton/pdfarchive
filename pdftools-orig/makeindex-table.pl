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

my $pctw = 100;
my @cw=();
for (my $j=$cols; $j > 0; $j--) {
    my $tcw = int(0.5 + ($pctw/$j) );
    $pctw -= $tcw;
    $cw[ $j ] = $tcw;
};
$pctw = 100;
my @dw=();
for (my $j=$dircols; $j > 0; $j--) {
    my $tcw = int(0.5 + ($pctw/$j) );
    $pctw -= $tcw;
    $dw[ $j ] = $tcw;
};
$BASEDIR=$opt_b . '/' . $opt_d;
$BASEURL=$opt_u . '/' . $opt_d;

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
    print STDERR "BASEURL=$u\n";

    my $reldir = $d;
    if ($d ne $BASEDIR) {
	$reldir =~ s/^$BASEDIR\///;
    } else {
	$reldir = "";
    }
    print STDERR "RELDIR=$reldir\n";

    my $title = "$opt_d RPG PDFs";

    if ($d ne $BASEDIR) {
	$title = substr($d,rindex($d,'/')+1);
    }

    open (OUTPUT,">index.html") or die;
    select OUTPUT;

    print <<EOF;
<!DOCTYPE html>
<html>
<head>
<link href="/css/rpg.css" rel="stylesheet" type="text/css" />
<title>
$title
</title>
</head>
<body>
<h1>
$title
</h1>
<hr>
<h2>
Search Text
</h2>
<a href="/cgi-bin/search-$opt_d.cgi">Search for text in $opt_d RPG PDF collection</a>
<p>
<hr>
<a href="$u"><img src="/rpgicons/back.gif" alt="[ Back arrow ]" />Enclosing directory</a>
<p>
<hr>
<table cols=\"$cols\" width=\"100\%\">
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
    my $alternator=0;
    for (@f) {
	next unless ((/\.pdf$/i) || (/.jpg/i));
	$i++;
	$filename = $_;
	s/#/%23/;
	s/ /%20/;
	$tn=substr($filename,0,(length($filename)-4));
	$thumb = $tn . ".jpg";
	$textname = $tn . ".txt";
	$textname =~ s/#/%23/g;
	$textname =~ s/ /%20/g;
	$thumb =~ s/#/%23/g;
	$thumb =~ s/ /%20/g;
	if ($i==1) {  
	    my $trclass="alt";
	    if ($alternator) {
		$trclass="base";
		$alternator=0;
	    } else {
		$alternator=1;
	    }
	    print "<tr class=\"$trclass\">\n";
	}
	print "<td width=\"" . $cw[ $i ] . "\%\">\n";
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
	if ($i < $cols) {
	    for ($i; $i <= $cols; $i++) {
		print "<td width=\"$cw[$i]\%\"></td>";
	    }
	}
	print "</tr>\n";
    }
    print "</table>\n";
    print "<hr>\n";
    print "<table cols=\"$dircols\" width=\"100\%\">\n";
    $i=0;
    $alternator = 0;
    for (@d) {
	next if ((/^Text$/) or (/^Thumbs$/));
	$i++;
	chomp;
	$filename = $_;
	if ($i==1) {  
	    my $trclass="alt";
	    if ($alternator) {
		$trclass="base";
		$alternator=0;
	    } else {
		$alternator=1;
	    }
  	    print "<tr class=\"$trclass\">\n";
	}
	print "<td width=\"" . $dw[ $i ] . "\%\">\n";
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
	print "<a href=\"$_\"><img src=\"/rpgicons/folder.png\" alt=\"\[$tn\]\" title=\"[$tn]\">$tn</a>$pad<p>\n";
	print "</td>\n";
	if ($i==$dircols) {
	    print "</tr>\n";
	    $i=0;
	}
    }
    if ($i < $cols) {
	for ($i; $i <= $cols; $i++) {
	    print "<td width=\"$dw[$i]\%\"></td>";
	}
	print "</tr>\n";
    }

    print <<EOF;
</table>
<hr>
<a href="$u"><img src="/icons/back.gif" alt="[ Back arrow ]" />Enclosing directory</a>
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
