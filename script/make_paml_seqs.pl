#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Util::Logger;
use Bio::Phylo::IO qw'parse_matrix parse_tree';

# process command line arguments
my ( $infile, $treefile, $verbose );
GetOptions(
	'infile=s'   => \$infile,
	'treefile=s' => \$treefile,
	'verbose+'   => \$verbose,
);

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new( '-class' => 'main', '-level' => $verbose );

# parse matrix
my $matrix = parse_matrix(
	'-format' => 'phylip',
	'-file'   => $infile,
	'-type'   => 'dna',
);

# parse tree
my $tree = parse_tree(
	'-format' => 'newick',
	'-file'   => $treefile,
);

# prune sequences not in tree
my %tips = map { $_->get_name => 1 } @{ $tree->get_terminals };
my @delete;
$matrix->visit(sub{
	my $row = shift;
	my $name = $row->get_name;
	if ( not $tips{$name} ) {
		$log->info("going to remove $name from $infile");
		push @delete, $row;	
	}
});
$matrix->delete($_) for @delete;

# needs to be multiple of 3
my $nchar = $matrix->get_nchar;
my $remainder = $nchar % 3;
my $pamlnchar = $nchar - $remainder;
my $ntax = $matrix->get_ntax;
$log->warn("going to truncate $infile by $remainder characters") if $remainder;

# print phylip header
print '  ', $ntax, '  ', $pamlnchar, "\n";

# print sequences
for my $row ( @{ $matrix->get_entities } ) {
	my $name = $row->get_name;
	my $seq  = $row->get_char;
	my $codons = substr $seq, 0, $pamlnchar;
	print "\n", $name, "\n", $codons, "\n";
}