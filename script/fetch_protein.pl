#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Bio::DB::GenBank;
use Bio::DB::Query::GenBank;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# this script takes an input alignment, parses the GIs out of the
# sequence names in the alignment, and attempts to fetch the 
# associated protein translations, which it writes out as FASTA

# process command line arguments
my ( $infile, $format, $type, $csv );
GetOptions(
	'infile=s' => \$infile,
	'format=s' => \$format,
	'type=s'   => \$type,
	'csv=s'    => \$csv,
);

# instantiate map object
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# parse input file
my ($matrix) = @{
	parse(
		'-format' => $format,
		'-file'   => $infile,
		'-type'   => $type,
		'-as_project' => 1,
	)->get_items(_MATRIX_)
};

# get GIs from input file
my @ids;
for my $row ( @{ $matrix->get_entities } ) {
	my $label = $map->parse_label( $row->get_name );
	my $gi = $map->get_gi_for_label($label);
	push @ids, $gi;
}

# compose query object
my $query_str = join ' or ', map { $_ . '[GI]' } grep { /\d+/ } @ids;
my $query_obj = Bio::DB::Query::GenBank->new( '-db' => 'nucleotide', '-query' => $query_str );

# run query
my $gb_obj = Bio::DB::GenBank->new;
my $stream_obj = $gb_obj->get_Stream_by_query($query_obj);
 
# iterate over results
 while (my $seq = $stream_obj->next_seq) {   
 
	# verify that local and remote taxon IDs match
	my $id = $seq->primary_id;
	my $taxon_id = $seq->species->ncbi_taxid;
	my $phylip_name = $map->get_phylip_for_gi($id);
	if ( $taxon_id == $map->get_taxonID_for_gi($id) && $phylip_name ) {
	
		# get the coding sequence	
		for my $feat ( $seq->get_SeqFeatures ) {
			if ( $feat->primary_tag eq 'CDS' ) {
				my ($feat_seq) = @{ $feat->{'_gsf_tag_hash'}->{'translation'} };
				print '>', $phylip_name, "\n", $feat_seq, "\n";
			}
		}
		
	}
	else {
		warn "wrong species for GI $id in $infile";
	}
}