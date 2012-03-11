#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::Phylo::Cobra::TaxaMap;

# process command line arguments
my ( $infile, $csv );
GetOptions(
    'infile=s' => \$infile,
    'csv=s'    => \$csv,
);

# fetch first tree
my ($tree) = @{
    parse(
        '-format' => 'nexus',
        '-file'   => $infile,
        '-as_project' => 1,
    )->get_items(_TREE_)
};

# instantiate taxa map
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# rename tips
for my $tip ( @{ $tree->get_terminals } ) {
    my $name = $tip->get_name;
    my $label = $map->parse_label($name);
    my $phylip = $map->phylip($label);
    $tip->set_name($phylip);
}

# print output
print $tree->to_newick;