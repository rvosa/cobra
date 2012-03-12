#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Getopt::Long;

my ( $infile );
GetOptions(
	'infile=s' => \$infile,
);

unless ( $infile && -f $infile ) {
	die "Usage: $0 --infile=<infile>";
}

unless ( -s $infile ) {
	warn "*** $infile has 0 bytes, quitting";
	exit 0;
}

my ( $forest ) = @{ parse(
	'-format' => 'nexus',
	'-file'   => $infile,
	'-as_project' => 1,
)->get_forests };

my $tree = $forest->first;
my $nodes = scalar( @{ $tree->get_entities } ) - 2;

# (10) Positive Selection
print "10\n";

# (3) Test whether a branch (or branches) in the tree evolves under different dN and dS than the rest of the tree.
print "3\n";

# Choose Genetic Code
# (1):[Universal] Universal code. (Genebank transl_table=1).
print "1\n";

# Select a codon data file
print "$infile\n\n";

# Site-to-site rate variation model
# (1):[None] No site-by-site rate variation.
print "1\n";

# Nucleotide Substitution Model
# (1):[Default] MG94xHKY85. Only corrects for transition/transversion bias.
print "1\n";

# Amino Acid Class Model
# (1):[Default] Single non-synonymous rate class. All changes are equivalent
print "1\n";

# A tree was found in the data file:
# Would you like to use it:
print "Y\n";

# Choose the branch to test:
print "$_\n" for 1 .. $nodes;
print "d\n"; # done

# Parameters to test:
# (1):[1] Non-synonymous rate parameter nsClass1
print "1\n";
print "d\n"; # done
