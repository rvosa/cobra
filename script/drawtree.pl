#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Treedrawer;
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Factory;

my $fac = Bio::Phylo::Factory->new(
    'node' => 'Bio::Phylo::Forest::DrawNode',
    'tree' => 'Bio::Phylo::Forest::DrawTree',
);

# processing command line arguments
my ( $infile, $format, $outfile, %defines, $verbose );
GetOptions(
    'infile=s'  => \$infile,
    'format=s'  => \$format,
    'outfile=s' => \$outfile,
    'define=s'  => \%defines,
    'verbose+'  => \$verbose,
);

# initializing logger, verbosity is set with --verbose command line arg
my $logger = Bio::Phylo::Util::Logger->new( '-level' => $verbose );

# parse first tree from input file
$logger->info("Going to read $format tree from $infile");
my ($tree) = @{ parse(
    '-format'     => $format,
    '-file'       => $infile,
    '-as_project' => 1,
    '-factory'    => $fac,
)->get_items(_TREE_) };

# instantiate tree drawer
$logger->info("Going to draw using these settings: " . Dumper(\%defines));
my $td = Bio::Phylo::Treedrawer->new(
    '-tree'   => $tree,
    '-height' => $tree->get_ntax * 50,
    %defines,
);

# open output handle
open my $fh, '>', $outfile or die "Can't open $outfile: $!";
binmode($fh); # this so that binary bitmaps are also printed correctly

# write output to file
print $fh $td->draw;