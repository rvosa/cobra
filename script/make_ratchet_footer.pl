#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $outgroup, $constr, $format, $ratchet );
GetOptions(
    'outgroup=s'   => \$outgroup,
    'constraint=s' => \$constr,
    'format=s'     => \$format,
    'ratchet=s'    => \$ratchet,
);

# parse constraint tree (typically ncbi tree)
my ($tree) = @{ parse(
    '-format' => $format,
    '-file'   => $constr,
    '-as_project' => 1,
)->get_items(_TREE_) };

# replace spaces with underscores, remove quotes, unset branch lengths
$tree->visit(sub{
    my $node = shift;
    if ( $node->is_terminal ) {
        my $name = $node->get_name;
        $name =~ s/ /_/g;
        $name =~ s/'//g;
        $node->set_name($name);
    }    
    $node->set_branch_length(undef);
});

# serialize back to newick
my $newick = $tree->to_newick;

# print command blocks
print <<"FOOTER";
BEGIN ASSUMPTIONS;
		OPTIONS DEFTYPE = ORD;
END;

BEGIN PAUP;
		OUTGROUP ${outgroup};
		CONSTRAINTS ncbi (BACKBONE) = ${newick}
		EXECUTE ${ratchet};
END;
FOOTER
