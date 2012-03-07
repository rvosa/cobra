#!/usr/bin/perl
use strict;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Data::Dumper;

my ( $infile, $format, $csv );
GetOptions(
    'infile=s' => \$infile,
    'format=s' => \$format,
    'csv=s'    => \$csv,
);

my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);
my %seen = map { $_ => 1 } $map->get_all_taxonIDs;

my ($forest) = @{
    parse(
        '-format' => $format,
        '-file'   => $infile,
        '-as_project' => 1,
    )->get_items(_FOREST_)
};

for my $tree ( @{ $forest->get_entities } ) {
    for my $tip ( @{ $tree->get_terminals } ) {
        my $taxon = $tip->get_taxon;
        META: for my $meta ( @{ $taxon->get_meta('skos:closeMatch', 'skos:exactMatch') } ) {
            my $obj = $meta->get_object;
            if ( $obj =~ m|http://purl.uniprot.org/taxonomy/(\d+)| ) {
                my $id = $1;
                $tip->set_name($id);
                $taxon->set_name($id);
                last META;
            }
        }
    }
}

my $matrix = $forest->make_matrix;
my %simple;
my $nchar;
for my $row ( @{ $matrix->get_entities } ) {
    my $name = $row->get_name;
    if ( $seen{$name} ) {
        my @char = $row->get_char;
        $simple{$name} = \@char;
        $nchar = scalar @char;
    }
}

my %informative = map { $_ => [] } keys %simple;
my @names = keys %simple;
my %pattern;
for my $i ( 0 .. ( $nchar - 1 ) ) {
    my ( %char, @char, $pattern );    
    for my $name ( @names ) {
        $char{$simple{$name}->[$i]}++;
        push @char, $simple{$name}->[$i];
        $pattern .= $simple{$name}->[$i];
    }
    if ( scalar(keys(%char)) > 1 && ! $pattern{$pattern} ) {
        for my $j ( 0 .. $#names ) {
            push @{ $informative{$names[$j]} }, $char[$j];
        }
    }
    $pattern{$pattern}++;
}
for my $row ( keys %informative ) {
    print $row, "\t", join('', @{ $informative{$row} } ), "\n";
}
