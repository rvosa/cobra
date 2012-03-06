#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::Factory;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

my $project = parse(
    '-format'     => 'newick',
    '-file'       => shift(@ARGV),
    '-as_project' => 1,
);

my ($forest) = @{ $project->get_items(_FOREST_) };
my $taxa     = $forest->make_taxa;
my $factory  = Bio::Phylo::Factory->new;

for my $taxon ( @{ $taxa->get_entities } ) {
    my $name = $taxon->get_name;
    $name =~ s/['"]//g;
    $name =~ s/_/ /g;
    $_->set_name($name) for @{ $taxon->get_nodes };
    my $code = join '', map { substr $_, 0, 5 } map { uc $_ } split / /, $name;
    $taxon->add_meta(
        $factory->create_meta(
            '-namespaces' => { 'pxml'  => _NS_PHYLOXML_ },
            '-triple' => { 'pxml:code' => $code },
        )
    );
}

print unparse( '-format' => 'phyloxml', '-phylo' => $project );