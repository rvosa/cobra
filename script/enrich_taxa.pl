#!/usr/bin/perl
use Bio::Phylo::Factory;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::Logger ':levels';
use LWP::UserAgent;
use strict;
use Getopt::Long;

# instantiate logger to see what we're doing here in in main
my $log = Bio::Phylo::Util::Logger->new( '-class' => 'main', '-level' => INFO );

# instantiate and populate CSV map object
my $map = Bio::Phylo::Cobra::TaxaMap->new(shift @ARGV);

# create a phylows client
my $fac = Bio::Phylo::Factory->new;
my $client = $fac->create_client( 
	'-base_uri'  => 'http://nexml-dev.nescent.org/nexml/phylows/ubionb/phylows/',
	'-authority' => 'uBioNB',
);

# run a query through the client for each distinct scientific name in the CSV
for my $name ( $map->get_distinct_binomials ) {
	$log->info($name);
	my $desc = $client->get_query_result( 
		'-query'   => $name, 
		'-section' => 'taxon',
	);
	for my $res ( @{ $desc->get_entities } ) {
		my $proj = $client->get_record( '-guid' => $res->get_guid );
		print $proj->to_nexus, "\n";
	}
}