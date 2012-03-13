#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::Factory;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';
use Getopt::Long;

# get command line arguments
my ( $infile, $taxamap, $format );
GetOptions(
    'infile=s'  => \$infile,
    'format=s'  => \$format,
    'taxamap=s' => \$taxamap,
);

# parse input tree
my $project = parse(
    '-format'     => $format || 'newick',
    '-file'       => $infile,
    '-as_project' => 1,
);

# parse input table
my $map = Bio::Phylo::Cobra::TaxaMap->new($taxamap);

# create taxa for the forest object
my ($forest) = @{ $project->get_items(_FOREST_) };
my $taxa     = $forest->make_taxa;

# instantiate factory to make annotation objects
my $factory  = Bio::Phylo::Factory->new;

# iterate over newly created taxa
for my $taxon ( @{ $taxa->get_entities } ) {
    my $name = $taxon->get_name;
    
    # clean up name in case it has quotes and/or underscores
    $name =~ s/['"]//g;
    $name =~ s/_/ /g;
    $_->set_name($name) for @{ $taxon->get_nodes };
    
    # code is obtained form taxa.csv
    my $code = $map->get_code_for_binomial($name);
    
    # attach code as annotation
    $taxon->add_meta(
        $factory->create_meta(
            '-namespaces' => { 'pxml'  => _NS_PHYLOXML_ },
            '-triple' => { 'pxml:code' => $code },
        )
    );
    
    # attach scientific_name as annotation
    $taxon->add_meta(
        $factory->create_meta(
            '-namespaces' => { 'pxml'  => _NS_PHYLOXML_ },
            '-triple' => { 'pxml:scientific_name' => $name },
        )
    );    
}

# write output
print unparse( '-format' => 'phyloxml', '-phylo' => $project );