#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Util::Logger;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $csv, $infile, $verbosity );
GetOptions(
    'csv=s'    => \$csv,
    'infile=s' => \$infile,
    'verbose+' => \$verbosity,
);

# instantiate mapping
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new(
    '-level' => $verbosity,
    '-class' => 'main',
);

# parse matrix
my ($matrix) = @{parse(
    '-format' => 'fasta',
    '-type'   => 'dna',
    '-file'   => $infile,
)};

# rename labels
$matrix->visit(sub{
    my $row = shift;
    
    # reset the fasta definition line
    $row->set_generic('fasta_def_line' => undef);
    
    # read current label
    my $label = $row->get_name;
    
    # label already processed successfully
    if ( my $species = $map->get_binomial_for_label($label) ) {
        $log->info("already have species $species for label $label");
    }
    
    # attempt to parse
    else {
        if ( $label =~ /^([A-Z][a-z]*_[a-z]+_[a-zA-Z]*[0-9\.]+)/ ) {
            my $parsed = $1;
            if ( my $species = $map->get_binomial_for_label($parsed) ) {
                $log->info("succesfully identified label $parsed as species $species");
                $row->set_name($parsed);
            }
            else {
                $log->warn("couldn't parse label $label");
            }
        }
        else {
            $log->warn("couldn't parse label $label");
        }        
    }
});

# produce output
print unparse(
    '-format' => 'fasta',
    '-phylo'  => $matrix,
);