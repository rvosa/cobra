#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

my ( $infile, $format );
GetOptions(
    'infile=s' => \$infile,
    'format=s' => \$format,
);

my $project = parse(
    '-format' => $format,
    '-file'   => $infile,
    '-as_project' => 1,
);

for my $taxon ( @{ $project->get_items(_TAXON_) } ) {
    my $name = $taxon->get_name;
    if ( $name =~ m/^([^_]+_[^_]+)/ ) {
        my $binomial = $1;
        print $name, "\t", $binomial, "\n";
    }
}