use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';
use Data::Dumper;

# process command line arguments
my ( $infile, $format, $csv, $extension, $verbosity );
GetOptions(
    'stem=s'      => \$infile,
    'format=s'    => \$format,
    'csv=s'       => \$csv,
    'extension=s' => \$extension,
);

# instantiate helper objects
my $fac = Bio::Phylo::Factory->new;
my $log = Bio::Phylo::Util::Logger->new;
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# parse infile
my $project = parse(
    '-format'     => $format,
    '-file'       => "$infile.$extension",
    '-as_project' => 1
);

# get tree block from project
my ($forest) = @{ $project->get_items(_FOREST_) };

# PHYML trees are unrooted with a basal trichotomy.
# SDI requires rooted trees. Our best bet is to perform
# midpoint rooting.
my ($tree) = @{ $forest->get_entities };
my $midpoint = $tree->get_midpoint;
my ($tallest) = sort { $b->get_branch_length <=> $a->get_branch_length } @{ $midpoint->get_children };
$tallest->set_root_below;

# make or fetch taxa block for trees block
my $taxa = $forest->make_taxa;
$project->insert($taxa);

# iterate over taxa
for my $taxon ( @{ $taxa->get_entities } ) {
    my $phylip = $taxon->get_name;
    
    my $code     = $map->get_code_for_phylip($phylip);
    my $binomial = $map->get_binomial_for_phylip($phylip);
    my $label    = $map->get_label_for_phylip($phylip);
            
	# attach scientific name and code as phyloxml annotations
	my %ns = ( 'pxml' => _NS_PHYLOXML_ );
	update_meta( $taxon, 'pxml:code' => $code, %ns );
	update_meta( $taxon, 'pxml:scientific_name' => $binomial, %ns );
	
	# use original sequence label as node name
	$taxon->get_nodes->[0]->set_name($label) if $label;
}

print unparse( '-format' => 'phyloxml', '-phylo' => $project );

# helper subroutine that attaches $predicate => $value to $object
# with namespace(s) %ns
sub update_meta {
    my ( $object, $predicate, $value, %ns ) = @_;
    my ( $meta ) = @{ $object->get_meta($predicate) };
    if ( $meta ) {
        $meta->set_triple( $predicate => $value );
    }
    else {
        $object->add_meta(
            $fac->create_meta(
                '-namespaces' => \%ns,
                '-triple' => { $predicate => $value },
            )
        );
    }
}