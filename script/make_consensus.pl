#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';
use Bio::Phylo::Factory;

my ( $infile, $csv );
GetOptions(
    'infile=s' => \$infile,
    'csv=s'    => \$csv,
);

my %seen;
my $nexus_string;
{
    open my $fh, '<', $infile or die $!;
    while(<$fh>) {
        if ( /tree PAUP_\d+ = \[&U\] (\(.+\);)/ ) {
            my $newick = $1;
            $nexus_string .= $_ if not $seen{$newick}++;
        }
        else {
            $nexus_string .= $_;
        }
    }
}

my $project = parse(
    '-format' => 'nexus',
    '-string' => $nexus_string,
    '-as_project' => 1
);

my ($forest) = @{ $project->get_items(_FOREST_) };
my $tree = $forest->make_consensus;
$project->delete($forest);
my $fac = Bio::Phylo::Factory->new;
$forest = $fac->create_forest;
$forest->insert($tree);
my $taxa = $forest->make_taxa;
$forest->set_taxa($taxa);
$project->insert($taxa,$forest);

my $outgroup = $tree->get_by_name("'mrp_outgroup'");
$outgroup->set_root_below;

$tree->visit(
    sub {
        my $node = shift;
        if ( scalar(@{ $node->get_children }) > 2 ) {
            warn $node->to_newick;
        }
    }
);
$tree->resolve;

my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);
$taxa->visit(
    sub {
        my $taxon = shift;
        my $binomial = $taxon->get_name;
        $binomial =~ s/'//g;
        $binomial =~ s/_/ /g;
        my $code = $map->get_code_for_binomial($binomial);
        if ( $code ) {
            $taxon->add_meta(
                $fac->create_meta(
                    '-namespaces' => { 'pxml' => _NS_PHYLOXML_ },
                    '-triple' => { 'pxml:code' => $code },
                )
            );
        }
        $taxon->add_meta(
            $fac->create_meta(
                '-namespaces' => { 'pxml' => _NS_PHYLOXML_ },
                '-triple' => { 'pxml:scientific_name' => $binomial },
            )
        );            
    }
);

print unparse( '-format' => 'phyloxml', '-phylo' => $project );