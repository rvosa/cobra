#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO 'parse_matrix';

# process command line arguments
my $infile;
GetOptions(
	'infile=s' => \$infile,
);

# parse matrix
my $matrix = parse_matrix(
	'-format' => 'phylip',
	'-file'   => $infile,
	'-type'   => 'dna',
);

# needs to be multiple of 3
my $nchar = $matrix->get_nchar;
my $remainder = $nchar % 3;
my $pamlnchar = $nchar - $remainder;
my $ntax = $matrix->get_ntax;

# print phylip header
print '  ', $ntax, '  ', $pamlnchar, "\n";

# print sequences
for my $row ( @{ $matrix->get_entities } ) {
	my $name = $row->get_name;
	my $seq  = $row->get_char;
	my $codons = substr $seq, 0, $pamlnchar;
	print "\n", $name, "\n", $codons, "\n";
}