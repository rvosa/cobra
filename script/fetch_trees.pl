#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::PhyloWS::Client;
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse';

my $default_dir = $0;
$default_dir =~ s|fetch_trees\.pl$|../data/sourcetrees/|;

my $default_csv = $0;
$default_csv =~ s|fetch_trees\.pl$|../data/excel/taxa.csv|;

# read csv file
my $file = shift @ARGV || $default_csv;
my $dir = shift @ARGV || $default_dir;
my $map = Bio::Phylo::Cobra::TaxaMap->new($file);
my @ids = $map->get_distinct_taxonIDs;

# instantiate client
my $fac = Bio::Phylo::Factory->new;
my $client = $fac->create_client(
    '-base_uri'  => 'http://treebase.org/treebase-web/phylows/',
    '-authority' => 'TB2',
);

# fetch all trees for all identifiers
my %seen;
my @notseen;
for my $id ( @ids ) {
	eval {
		my $desc = $client->get_query_result(
			'-query'        => "tb.identifier.ncbi=$id",
			'-section'      => 'taxon',
			'-recordSchema' => 'tree',
		);
		
		# XXX there is something wrong or weird about the guid from treebase
		for my $res ( @{ $desc->get_entities } ) {
			my $guid = $res->get_guid;
			
			# don't download twice
			if ( not $seen{$guid} ) {
				
				# fetch data
				my $url  = $guid . '?format=nexml';
				my $proj = parse( 
					'-format'     => 'nexml', 
					'-url'        => $url,
					'-as_project' => 1,
				);
				
				# write the result to a file based on the GUID.
				# this should clobber instance where multiple taxa in our list
				# were in the same study. that's the behavior that we want.
				my $outfile = $guid;
				$outfile =~ s|^.+:(.+)$|$dir/$1.xml|;			
				open my $fh, '>', $outfile or die "Can't open $outfile: $!";
				print $fh $proj->to_xml, "\n";
				warn "taxon $id written to $outfile";
			}
			
			# counting seen files so we can count overlap
			$seen{$guid}++;
		}
		
		# zero hits
		push @notseen, $id unless scalar( @{ $desc->get_entities } );
	};
	if ( $@ ) {
		warn "problem with taxon $id: $@";
	}
}

# reporting back
my $ntax = scalar(@ids);
my $filecount = scalar(keys(%seen));
my $average = $ntax / $filecount;
print "$average overlapping taxa in $filecount files\n";
print "taxa with 0 hits:\n";
print join "\n", @notseen;

__DATA__
0.391691394658754 overlapping taxa in 337 files
taxa with 0 hits:
111304
186611
196418
310520
33626
338837
338838
51750
61970
672774
865857
8781