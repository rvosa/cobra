#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $infile, $csv );
GetOptions(
    'infile=s' => \$infile,
    'csv=s'    => \$csv,
);

# parse fasta alignment
my ($matrix) = @{
    parse(
        '-format' => 'fasta',
        '-type'   => 'dna',
        '-file'   => $infile,
        '-as_project' => 1,
    )->get_items(_MATRIX_)
};

# instantiate map object
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# replace names with 10-character codes
$matrix->visit(sub{
    my $row = shift;
    if ( my $name = $row->get_name ) {
        if ( $name =~ /^([^_]+_[^_]+_[^_]+)/ ) {
            my $three_part_name = $1;
            my $code = $map->get_code_for_label($three_part_name);
            $row->set_name($code);
        }
    }
});

# print out to phylip
print unparse( '-format' => 'phylip', '-phylo' => $matrix );