#!/usr/bin/perl
use strict;
use Data::Dumper;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::Phylo::Util::Logger ':levels';

# mapping so that we can define on the cli which objects
# to fetch from the input file
my %typemap = (
    'tree'   => _TREE_,
    'matrix' => _MATRIX_,
);

# processing command line arguments
my ( $infile, $format, $thing, $verbose, %defines );
GetOptions(
    'infile=s' => \$infile,
    'format=s' => \$format,
    'thing=s'  => \$thing,
    'verbose+' => \$verbose,
    'define=s' => \%defines,
);

# initializing logger, verbosity is set with --verbose command line arg
my $logger = Bio::Phylo::Util::Logger->new( '-level' => $verbose );

# parse first tree from input file
$logger->info("Going to read $format $thing from $infile");
my ($object) = @{ parse(
    '-format'     => $format,
    '-file'       => $infile,
    '-as_project' => 1,
    %defines,
)->get_items($typemap{lc $thing}) };

print $object->get_ntax;
