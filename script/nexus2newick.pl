#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::IO qw'parse parse_matrix';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $infile, $csv, $seqfile );
GetOptions(
    'infile=s'  => \$infile,
    'seqfile=s' => \$seqfile,
    'csv=s'     => \$csv,
);

# instantiate helper objects
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);
my $log = Bio::Phylo::Util::Logger->new;

# fetch matrix
my $matrix = parse_matrix(
    '-format' => 'fasta',
    '-file'   => $seqfile,
    '-type'   => 'dna',    
);

# fetch first tree
my ($tree) = @{
    parse(
        '-format' => 'nexus',
        '-file'   => $infile,
        '-as_project' => 1,
    )->get_items(_TREE_)
};

# prune tips not in alignment
my @prune_me;
my %in_matrix;
$matrix->visit(
    sub {
        my $row = shift;
        my $label = $map->parse_label($row->get_name);
        $in_matrix{$label} = 1;
    }
);
for my $tip ( @{ $tree->get_terminals } ) {
    my $label = $map->parse_label($tip->get_name);
    if ( not $in_matrix{$label} ) {
        $log->warn("*** Pruning $label");
        push @prune_me, $tip;
    }
}
$tree->prune_tips(\@prune_me);

# rename tips
for my $tip ( @{ $tree->get_terminals } ) {
    my $name = $tip->get_name;
    my $label = $map->parse_label($name);
    my $phylip = $map->phylip($label);
    $tip->set_name($phylip);
}

# print output
print $tree->to_newick;