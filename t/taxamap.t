#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use Bio::DB::GenBank;
use Bio::DB::Query::GenBank;
use Bio::Phylo::Cobra::TaxaMap;

my $csv = $0;
$csv =~ s|taxamap\.t$|../data/excel/taxa.csv|;
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# test: all phylip labels in a given gene must be unique
my @genes = $map->get_distinct_genes;
for my $gene ( @genes ) {
    my @phylip = $map->get_phylip_for_gene($gene);
    my %unique = map { $_ => 1 } @phylip;
    my @unique = keys %unique;
    ok( scalar(@phylip) == scalar(@unique), "distinct phylip labels for gene $gene");
}

# test: gis must be unique across entire table
my @all_gis = grep { /\d+/ } $map->get_all_gis;
my %seen;
for my $gi ( @all_gis ) {
    ok( ! $seen{$gi}++, "$gi is distinct");
}

# run query
my $gb_obj = Bio::DB::GenBank->new;
 
# iterate over results
for my $gi ( @all_gis ) {
    my $seq = $gb_obj->get_Seq_by_gi($gi);
    
	# verify that local and remote taxon IDs match
	my $remote_taxid = $seq->species->ncbi_taxid;
	my $local_taxid = $map->get_taxonID_for_gi($gi);
    ok( $remote_taxid == $local_taxid, "verify taxon ID for GI $gi" );
    
    # verify that local and remote binomials match
    my $local_binomial = $map->get_binomial_for_gi($gi);
    my $remote_binomial = $seq->species->binomial('FULL');
    ok( $remote_binomial eq $local_binomial, "verify binomials match: $remote_binomial <=> $local_binomial (gi: $gi)" );
    
    sleep(5);
}
