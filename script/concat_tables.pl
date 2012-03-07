#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::Cobra::TaxaMap;

# get command line arguments
my ( $outgroup, $dir, $csv ) = ( 'mrp_outgroup' );
GetOptions(
    'dir=s' => \$dir,
    'csv=s' => \$csv,
    'outgroup=s' => \$outgroup,
);

# create taxa map
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# concatenate tables
my %table = ( $outgroup => undef );
opendir my $dh, $dir or die $!;
while( my $entry = readdir $dh ) {
    if ( $entry =~ /\.dat/ ) {
        warn $entry;
        open my $fh, '<', "$dir/$entry" or die $!;
        my $nchar;
        my %seen;
        while(<$fh>) {
            chomp;
            if ( /\S/ ) {
                my ( $key, $value ) = split /\t/, $_;
                $nchar = length($value);
                $seen{$key} = 1;
                $table{$key} .= $value;
            }
        }
        for my $row ( keys %table ) {
            if ( not $seen{$row} ) {
                my $char = $row eq $outgroup ? '0' : '?';
                $table{$row} .= $char x $nchar;
            }
        }
    }
}

# create and populate matrix object
my $fac = Bio::Phylo::Factory->new;
my $matrix = $fac->create_matrix( '-type' => 'standard' );
for my $row ( sort { $a cmp $b } keys %table ) {
    my $binomial = $map->get_binomial_for_taxonID($row) || $outgroup;
    $matrix->insert(
        $fac->create_datum(
            '-type' => 'standard',
            '-name' => "'$binomial'",
            '-char' => $table{$row}
        )
    )
}

my @rows = sort { $a->get_name cmp $b->get_name } @{ $matrix->get_entities };
$matrix->clear;
$matrix->insert($_) for @rows; 

# print output
print "#NEXUS\n", $matrix->make_taxa->to_nexus, $matrix->to_nexus;
