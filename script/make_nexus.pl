#!/usr/bin/perl
use strict;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# instantiate factory
my $fac = Bio::Phylo::Factory->new;

# process command line arguments
my ( $treefile, $treeformat, $datafile, $dataformat, $datatype );
GetOptions(
    'treefile=s'   => \$treefile,
    'treeformat=s' => \$treeformat,
    'datafile=s'   => \$datafile,
    'dataformat=s' => \$dataformat,
    'datatype=s'   => \$datatype,
);

# read trees from tree file
my ($forest) = @{
    parse(
        '-format' => $treeformat,
        '-file'   => $treefile,
        '-as_project' => 1,
    )->get_items(_FOREST_)
};

# read data from data file
my ($matrix) = @{
    parse(
        '-format' => $dataformat,
        '-file'   => $datafile,
        '-type'   => $datatype,
    )
};

# reconcile taxa
my $proj = $fac->create_project;
my $treetaxa = $forest->make_taxa;
my $datataxa = $matrix->make_taxa;
my $merged = $treetaxa->merge_by_name($datataxa);
$forest->set_taxa($merged);
$matrix->set_taxa($merged);
my @sorted = sort { $a->get_name cmp $b->get_name } @{ $matrix->get_entities };
$matrix->clear;
$matrix->insert($_) for @sorted;

# print result
print $proj->insert($merged,$forest,$matrix)->to_nexus( -nodelabels => 1 );
