#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

# process command line arguments
my ( $infile, $csv );
GetOptions(
    'infile=s' => \$infile,
    'csv=s'    => \$csv,
);

# parse tree
my ($forest) = @{
    parse(
        '-format'     => 'phyloxml',
        '-file'       => $infile,
        '-as_project' => 1,
    )->get_items(_FOREST_)
};
my $tree = $forest->first;

# get phyloxml prefix
my $ns = $tree->get_namespaces;
my $pxml_prefix;
PREFIX: for my $prefix ( keys %{ $ns } ) {
    if ( $ns->{$prefix} eq _NS_PHYLOXML_ ) {
        $pxml_prefix = $prefix;
        last PREFIX;
    }
}

# create matrix
my $fac = Bio::Phylo::Factory->new;
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);
my $taxa   = $forest->make_taxa;
my $matrix = $fac->create_matrix(
    '-type' => 'standard',
    '-taxa' => $taxa,
);

# set annotation pxml:scientific_name as tip name and row name, create
# rows with state for venom
my @row;
for my $tip ( @{ $tree->get_terminals } ) {
    my $taxon = $tip->get_taxon;
    if ( my $binomial = $taxon->get_meta_object( "${pxml_prefix}:scientific_name" ) ) {
        $taxon->set_name($binomial);
        $tip->set_name($binomial);
        push @row, $fac->create_datum(
            '-type'  => 'standard',
            '-name'  => $binomial,
            '-taxon' => $taxon,
            '-char'  => [ my $venom = $map->get_venom_for_binomial($tip->get_name) || 0 ],            
        );
    }
}

# insert alphabetized rows
my @sorted = sort { $a->get_name cmp $b->get_name } @row;
$matrix->insert($_) for @sorted;

# sort taxa
my @taxa = sort { $a->get_name cmp $b->get_name } @{ $taxa->get_entities };
$taxa->clear;
$taxa->insert($_) for @taxa;

# print NEXUS
print $fac->create_project->insert($taxa,$forest,$matrix)->to_nexus;