#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $infile, $serializer, $mrbayesblock, $csv, $datatype );
GetOptions(
	'infile=s'       => \$infile,
	'serializer=s'   => \$serializer,
	'mrbayesblock=s' => \$mrbayesblock,
	'datatype=s'     => \$datatype,
	'csv=s'          => \$csv,
);

# parse data
my ($matrix) = @{parse(
	'-file'       => $infile,
	'-format'     => $serializer,
	'-type'       => $datatype,
	'-as_project' => 1,
)->get_items(_MATRIX_)};

# instantiate taxa map
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# rename tips
$matrix->visit(sub{
	my $row = shift;
	my $phylip = $map->phylip($row->get_name);
	$row->set_name($phylip);
});

# produce output
print "#NEXUS\n";
print $matrix->to_nexus( '-data_block' => 1 );

# print mrbayes block, if any
if ( $mrbayesblock ) {
	if ( -e $mrbayesblock ) {
		open my $fh, '<', $mrbayesblock or die $!;
		while(<$fh>) {
			print $_;
		}
	}
	else {
		print $mrbayesblock;
	}
}