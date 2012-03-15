use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';
use Data::Dumper;

# instantiate helper objects
my $fac = Bio::Phylo::Factory->new;
my $log = Bio::Phylo::Util::Logger->new;

# process command line arguments
my ( $infile, $format, $csv );
GetOptions(
    'stem=s'   => \$infile,
    'format=s' => \$format,
    'csv=s'    => \$csv,
);

# parse infile
my $project = parse(
    '-format'     => $format,
    '-file'       => "$infile.phylip_phyml_tree.txt",
    '-as_project' => 1
);

# read CSV file
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# get tree block from project
my ($forest) = @{ $project->get_items(_FOREST_) };

# resolve basal trichotomy, this is because PHYML writes NEWICK tree
# descriptions with three children at the root, which archeopteryx
# interprets as not fully resolved.
my ($tree) = @{ $forest->get_entities };
my $root = $tree->get_root;
my @children = @{ $root->get_children };
my $right1 = pop @children;
my $right2 = pop @children;
my $newroot = $fac->create_node;
$right1->set_parent($newroot);
$right2->set_parent($newroot);
$newroot->set_parent($root);
$tree->insert($newroot);

# make or fetch taxa block for trees block
my $taxa = $forest->make_taxa;
$project->insert($taxa);

# iterate over taxa
for my $taxon ( @{ $taxa->get_entities } ) {
    my $code = $taxon->get_name;
    $code =~ s/\d+$//;
    
    # lookup scientific name and sequence label
    my ($binomial,$label) = get_binomial_and_label_for_code($code);
    
    # this can only go wrong, if...
    if ( $binomial ) {
        
        # attach scientific name and code as phyloxml annotations
        my %ns = ( 'pxml' => _NS_PHYLOXML_ );
        update_meta( $taxon, 'pxml:code' => $code, %ns );
        #update_meta( $taxon, 'pxml:scientific_name' => $binomial, %ns );
        
        # use original sequence label as node name
        $taxon->get_nodes->[0]->set_name($label) if $label;
    }
    
    # ... we've had more than 10 sequences in the same file, i.e. with
    # - OPHIHANN1 (king cobra)
    # - OPHIHANN2 (idem)
    # - MUSMUSC01 (mouse)
    # - HOMOSAPI1 (human)
    else {
        warn 'wtf:', $code;
    }
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

sub get_binomial_and_label_for_code {
    my $code = shift;
    
    # read phylip file, get index of $code
    open my $phylipfile, '<', "$infile.phylip" or die $!;
    
    # read all lines except the ntax nchar line at the top
    my @phyliplines = grep { $_ !~ /^\s*\d+\s+\d+\s*$/ } <$phylipfile>;
    
    # read all definition files from the fasta
    open my $fastafile, '<', "$infile.fas" or die $!;
    my @fastalines = grep { /^>/ } <$fastafile>;
    
    for my $i ( 0 .. $#phyliplines ) {
        if ( $phyliplines[$i] =~ /^\Q$code\E\d*\s+/ ) {
            if ( $fastalines[$i] =~ />([^_]+_[^_]+_[^_]+)/ ) {
                my $label = $1;
                my $code = $map->code($label);
                my ($binomial) = sort { length($a) <=> length($b) } $map->get_binomial_for_code($code);
                warn $code, "\t", $label, "\t", $binomial;
                return $binomial, $label;
            }
        }
    }

}