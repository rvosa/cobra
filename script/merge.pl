#!/usr/bin/perl -w
use strict;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Factory;
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';
use Getopt::Long;

my $factory = Bio::Phylo::Factory->new;

# instantiate and process command line arguments
my (
    $treefile,
    $treeformat,
    %treedefines,
    $seqfile,
    $seqformat, 
    %seqdefines,
    $namelength,
    $outfile,
);

GetOptions(
    'treefile=s'    => \$treefile,    
    'treeformat=s'  => \$treeformat,
    'treedefines=s' => \%treedefines,
    'seqfile=s'     => \$seqfile,    
    'seqformat=s'   => \$seqformat,
    'seqdefines=s'  => \%seqdefines,
    'namelength=i'  => \$namelength,
    'outfile=s'     => \$outfile,
);

# parse the trees of out of the tree file
my ($forest) = @{ parse(
    '-format'     => $treeformat,
    '-file'       => $treefile,
    '-as_project' => 1,
    %treedefines
)->get_items(_FOREST_) };

# parse the alignment out of the sequence file
my ($matrix) = @{ parse(
    '-format' => $seqformat,
    '-file'   => $seqfile,
    '-as_project' => 1,
    %seqdefines
)->get_items(_MATRIX_) };

# make taxa blocks for forest and matrix
my $taxa = $factory->create_taxa;
my $taxon_for_name = {};

# create taxon objects for tips and sequences
for my $obj ( @{ $matrix->get_entities } ) {
    my $name = standardize_name($obj);
    link_taxon( $name, $obj, $taxa, $taxon_for_name );
}
for my $tree ( @{ $forest->get_entities } ) {
    for my $obj ( @{ $tree->get_entities } ) {
        if ( $obj->is_terminal ) {
            my $name = standardize_name($obj);
            link_taxon( $name, $obj, $taxa, $taxon_for_name );
        }
        else {
            
            # copy posterior probality to annotation
            my $posterior = $obj->get_name;
            $obj->add_meta(
                $factory->create_meta(
                    '-namespaces' => { 'bp' => _NS_BIOPHYLO_ },
                    '-triple' => { 'bp:posterior' => $posterior }
                )
            );            
        }
    }
}

# assign taxa container to forest and matrix, and insert in new project
$matrix->set_taxa($taxa);
$forest->set_taxa($taxa);
my $project = $factory->create_project;
$project->insert( $matrix, $forest );

# print to file
open my $fh, '>', $outfile or die $!;
print $fh $project->to_xml( '-compact' => 1 );

# create a name of $namelength, copy the old name to skos:altLabel
sub standardize_name {
    my $taxon = shift;
    
    # copy the original name to skos:altLabel annotation
    my $name = $taxon->get_name;
    $taxon->add_meta(
        $factory->create_meta(
            '-namespaces' => { 'skos' => _NS_SKOS_ },
            '-triple' => { 'skos:altLabel' => $name }
        )
    );
    
    # create a new name out of the first $namelength parts
    my $regex = '[^_]+_' x $namelength;
    $regex = substr $regex, 0, ( ( 6 * $namelength ) - 1 );
    if ( $name =~ /^($regex)/ ) {
        my $newname = $1;
        $taxon->set_name( $newname );
        return $newname;
    }
    else {
        die "$name !~ $regex";
    }
}

# check if a taxon with $name exists, if not, create it. Link
# this taxon to the focal object, add it to $taxon_for_name and
# insert in $taxa
sub link_taxon {
    my ( $name, $obj, $taxa, $taxon_for_name ) = @_;
    my $taxon;
    if ( $taxon_for_name->{$name} ) {
        $taxon = $taxon_for_name->{$name};
    }
    else {
        $taxon = $factory->create_taxon( '-name' => $name );
        $taxa->insert($taxon);
    }
    $obj->set_taxon($taxon);
    $taxon_for_name->{$name} = $taxon;    
}