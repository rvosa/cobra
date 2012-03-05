use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

my ( $infile, $format );
GetOptions(
    'infile=s'  => \$infile,
    'format=s'  => \$format,
);

my $project = parse(
    '-format'     => $format,
    '-file'       => $infile,
    '-as_project' => 1
);

print unparse( '-format' => 'phyloxml', '-phylo' => $project );