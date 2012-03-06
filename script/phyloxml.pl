use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

my $fac = Bio::Phylo::Factory->new;
my $log = Bio::Phylo::Util::Logger->new(
#    '-class' => 'Bio::Phylo::Unparsers::Phyloxml',
#    '-level' => DEBUG,
);

my ( $infile, $format, $treemap, %map );
GetOptions(
    'infile=s'  => \$infile,
    'format=s'  => \$format,
    'treemap=s' => \$treemap,
);

{
    open my $fh, '<', $treemap or die $!;
    while(<$fh>) {
        chomp;
        my @fields = split /,/, $_;
        my $key    = shift @fields;
        $map{$key} = \@fields;
    }
}

my $project = parse(
    '-format'     => $format,
    '-file'       => $infile,
    '-as_project' => 1
);

for my $taxon ( @{ $project->get_items(_TAXON_) } ) {
    my $name = $taxon->get_name;
    if ( $name =~ m/^([^_]+_[^_]+_[^_]+)/ ) {
        my $key = $1;
        if ( $map{$key} ) {
            my $code = join '', map { substr $_, 0, 5 } map { uc $_ } split / /, $map{$key}->[0];
            $taxon->add_meta(
                $fac->create_meta(
                    '-namespaces' => { 'pxml' => _NS_PHYLOXML_ },
                    '-triple' => { 'pxml:code' => $code },
                )
            );
            $taxon->add_meta(
                $fac->create_meta(
                    '-namespaces' => { 'pxml' => _NS_PHYLOXML_ },
                    '-triple' => { 'pxml:scientific_name' => $map{$key}->[0] },
                )
            )            
        }
        else {
            warn 'wtf:', $key;
        }
    }
    else {
        warn 'wtf: ', $name;
    }

}

print unparse( '-format' => 'phyloxml', '-phylo' => $project );