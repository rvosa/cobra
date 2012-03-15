#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $outgroup, $constr, $format, $ratchet, $csv );
GetOptions(
    'outgroup=s'   => \$outgroup,
    'constraint=s' => \$constr,
    'format=s'     => \$format,
    'ratchet=s'    => \$ratchet,
    'csv=s'        => \$csv,
);

# instantiate map
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# parse constraint tree (typically ncbi tree)
my ($tree) = @{ parse(
    '-format' => $format,
    '-file'   => $constr,
    '-as_project' => 1,
)->get_items(_TREE_) };

# replace names with codes, unset branch lengths
my %seen;
$tree->visit(sub{
    my $node = shift;
    if ( $node->is_terminal ) {
        my $name = $node->get_name;
        $name =~ s/'//g;
        my $code = $map->get_code_for_binomial($name);
        $node->set_name($code);
        $seen{$code} = [] unless $seen{$code};
        push @{ $seen{$code} }, $node;
    }    
    $node->set_branch_length(undef);
});

# serialize back to newick
my $newick = $tree->to_newick;

# prune now duplicated tips
for my $code ( keys %seen ) {
    if ( scalar( @{ $seen{$code} } ) > 1 ) {
        if ( $tree->is_clade( $seen{$code} ) ) {
            my @codes;
            for my $i ( 1 .. scalar( @{ $seen{$code} } ) ) {
                push @codes, $code;
            }
            my $pattern = '(' . join(',',@codes) . ')';
            $newick =~ s/\Q$pattern\E/$code/;
        }
        else {
            warn "problem with $code";
        }
    }
}

# print command blocks
print <<"FOOTER";
BEGIN ASSUMPTIONS;
		OPTIONS DEFTYPE = ORD;
END;

BEGIN PAUP;
		OUTGROUP ${outgroup};
		CONSTRAINTS ncbi (BACKBONE) = ${newick}
		EXECUTE ${ratchet};
        QUIT;
END;
FOOTER
