#!/usr/bin/perl
use strict;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::Phylo::Cobra::TaxaMap;

my ( $infile, $format, $csv );
GetOptions(
    'infile=s' => \$infile,
    'format=s' => \$format,
    'csv=s'    => \$csv,
);

my ($forest) = @{
    parse(
        '-format' => $format,
        '-file'   => $infile,
        '-as_project' => 1,
    )->get_items(_FOREST_)
};

my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);
for my $tree ( @{ $forest->get_entities } ) {
    for my $node ( @{ $tree->get_terminals } ) {
        if ( my $name = $node->get_name ) {
            $name =~ s/['"]//g;
            $name =~ s/_/ /g;
            my $id = $map->get_taxonID_for_binomial($name);
            $node->set_name($id);
        }
    }
}
my $matrix = $forest->make_matrix;
for my $row ( @{ $matrix->get_entities } ) {
    my $name = $row->get_name;
    my @char = $row->get_char;
    print $name, "\t", join('', @char), "\n";
}