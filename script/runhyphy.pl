#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
my ( $hyphydir, $executable, $infile ) = ( $ENV{'HYPHY_DIR'}, 'HYPHYMP' );
GetOptions(
	'hyphydir=s'   => \$hyphydir,
	'executable=s' => \$executable,
	'infile=s'     => \$infile,
);
unless( $hyphydir && -d $hyphydir && $executable && -x "${hyphydir}/${executable}" && $infile && -f $infile ) {
	die "Usage: $0 --infile=<infile> [--hyphydir=<hyphydir>] [--executable=<hyphy>]";
}

chdir $hyphydir;
system( "./$executable TemplateBatchFiles/BranchSiteREL.bf < $infile" ) == 0 or warn "problem executing ${infile}: $?\n";
