#!/usr/bin/perl
use Cwd;
use Getopt::Std;

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

chdir($BASEDIR) or die "$BASEDIR does not exist!";
blortit($BASEDIR);
exit 0;

sub blortit {
    my $newdir = shift;
    my @d = ();
    my @f = ();
    chdir($newdir);
    my $d = getcwd();
#    print STDERR "Executing in $d...\n";
    my $u=$d;
    $u =~ s/^$BASEDIR/$BASEURL/;
    $u=substr($u,0,1 + rindex($u,'/'));
#    print STDERR "BASEURL=$u\n";

    my $reldir = $d;
    if ($d ne $BASEDIR) {
	$reldir =~ s/^$BASEDIR\///;
    } else {
	$reldir = "";
    }
#    print STDERR "RELDIR=$reldir\n";

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
<script src="/scripts/jquery-1.7.1.min.js"></script>
<script src="/scripts/shade.js"></script>
<div id="wholepage">
<div id="header">
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
<hr>
<p>
</div>
<div id=\"content\">
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
    if (@f) {
	print "<div class=\"csstable\" id=\"filelist\">\n";
    }
    my $i=0;
    for (@f) {
	next unless ((/\.pdf$/i) || (/.jpg/i));
	$i++;
	$filename = $_;
	s/#/%23/g;
	s/ /%20/g;
	$tn=substr($filename,0,(length($filename)-4));
	$thumb = $tn . ".jpg";
	$textname = $tn . ".txt";
	$textname =~ s/#/%23/g;
	$textname =~ s/ /%20/g;
	$thumb =~ s/#/%23/g;
	$thumb =~ s/ /%20/g;
	$textlink = $BASEURL . "/Text/";
	if ($reldir) {
	    $textlink .= "$reldir/";
	}
	$textlink .= "$textname";
	print "<div class=\"pdffile\" id=\"fileid_" . $i . "\">\n";
	print "    <a href=\"./$_\"><img src=\"$BASEURL/Thumbs/";
	if ($reldir) { 
	    print "$reldir/";
	}
	print "$thumb\" alt=\"[$tn]\" title=\"[$tn]\"></a><br>\n";
	print "    <a href=\"./$_\">";
	print "$tn</a><br>\n";
	print "    <a href=\"$textlink\">[text]</a><br>\n";
	print "</div>\n";
    }
    if (@f) {
	print "</div>\n";
	print "<div style=\"clear: both\"></div>";
	print "<hr>\n";
    }
    if (@d) {
	print "<div class=\"csstable\" id=\"dirlist\">\n";
    }
    # On to the directory list
    $i=0;
    for (@d) {
	next if ((/^Text$/) or (/^Thumbs$/));
	$i++;
	chomp;
	$filename = $_;
	print "<div class=\"dir\" id=\"dirid_" . $i . "\">\n";
	print "    <a href=\"$_\">";
	print "<img src=\"/rpgicons/folder.png\" alt=\"\[$filename\]\" title=\"[$filename]\">$filename</a><p>\n";
	print "</div>\n";
    }
    if (@d) {
	print "</div>\n";
	print "<div style=\"clear: both\"></div>\n";
	print "<hr>\n";
    }
    print <<EOF;
</div>
<br>
<div style="clear: both"></div>
<div id="footer">
<a href="$u"><img src="/rpgicons/back.gif" alt="[ Back arrow ]" />Enclosing directory</a>
<br>
</div>
</div>
</div>
</body>
</html>
EOF
;
    close (OUTPUT);

    for (@d) {
	next if ((/^Text$/) or (/^Thumbs$/));
	$dir = $d . "/" . $_;
#	print STDERR "Recursing: calling blortit() on $dir\n";
	blortit($dir);
    }
}
