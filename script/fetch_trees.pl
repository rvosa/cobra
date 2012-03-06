#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::PhyloWS::Client;
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse';

# read csv file
my $file = shift @ARGV;
my $dir = shift @ARGV || 'result';
my $map = Bio::Phylo::Cobra::TaxaMap->new($file);
my @ids = $map->get_distinct_taxonIDs;

# instantiate client
my $fac = Bio::Phylo::Factory->new;
my $client = $fac->create_client(
    '-base_uri'  => 'http://treebase.org/treebase-web/phylows/',
    '-authority' => 'TB2',
);

# fetch all trees for all identifiers
for my $id ( @ids ) {
	eval {
		my $desc = $client->get_query_result(
			'-query'        => "tb.identifier.ncbi=$id",
			'-section'      => 'taxon',
			'-recordSchema' => 'tree',
		);
		
		# XXX there is something wrong or weird about the guid from treebase
		for my $res ( @{ $desc->get_entities } ) {
			my $url = $res->get_guid . '?format=nexus';
			my $proj = parse( 
				'-format'     => 'nexus', 
				'-url'        => $res->get_guid . '?format=nexus',
				'-as_project' => 1,
			);
			
			# write the result to a file based on the GUID.
			# this should clobber instance where multiple taxa in our list
			# were in the same study. that's the behavior that we want.
			my $outfile = $res->get_guid;
			$outfile =~ s|^.+:(.+)$|$dir/$1.nex|;			
			open my $fh, '>', $outfile or die $!;
			print $fh $proj->to_nexus, "\n";
			warn "taxon $id written to $outfile";
		}
	};
	if ( $@ ) {
		warn "problem with taxon $id: $@";
	}
}