#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Cobra::TaxaMap;

# process command line arguments
my ( $dir, $csv, $phylip_extension, $fasta_extension );
GetOptions(
    'dir=s'    => \$dir,
    'phylip=s' => \$phylip_extension,
    'fasta=s'  => \$fasta_extension,
    'csv=s'    => \$csv,
);

# initialize variables
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);
my ( @phylipnames, @fastanames, @genes );

# create directory handle
opendir my $dh, $dir or die $!;
while( my $entry = readdir $dh ) {
    
    # we map phylip names back to sequence labels,
    # so we start from the phylip file
    if ( $entry =~ m/\Q$phylip_extension\E$/ ) {
        
        # create full file names
        my $phylip = "$dir/$entry";
        my $fasta = $phylip;
        $fasta =~ s/\Q$phylip_extension\E$/$fasta_extension/;
        
        
        # read fasta file, store three-word labels
        {
            open my $fh, '<', $fasta or die $!;
            while(<$fh>) {
                chomp;
                if ( /^>(\S+)/ ) {
                    my $name = $1;
                    my $label = $map->parse_label($name);
                    push @fastanames, $label;
                    if ( $entry =~ m/^([^_]+)/ ) {
                        my $gene = $1;
                        push @genes, $gene;
                    }
                }
            }
        }
        
        # read phylip file, store 8-character-plus-integer names
        {
            open my $fh, '<', $phylip or die $!;
            LINE: while(<$fh>) {
                chomp;
                next LINE if /^\s*\d+\s+\d+\s*$/;
                if ( /^(\S+)/ ) {
                    my $name = $1;
                    push @phylipnames, $name;
                }
            }
        }
        
        # check if everything makes sense
        die $entry unless scalar(@fastanames) == scalar(@phylipnames);
        
    }
}

# create map
for my $i ( 0.. $#fastanames ) {
    $map->phylip( $fastanames[$i] => $phylipnames[$i] );
    $map->gene( $fastanames[$i] => $genes[$i] );
}
print $map->to_csv;