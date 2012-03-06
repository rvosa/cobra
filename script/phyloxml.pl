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

for my $taxon ( @{ $project->get_items(_TAXON_) } ) {
    my $name = $taxon->get_name;
    if ( $name =~ m/^([^_]+_[^_]+_[^_]+)/ ) {
        my $key = $1;
        if ( $map{$key} ) {
            my $code = join '', map { substr $_, 0, 5 } map { uc $_ } split / /, $map{$key}->[0];
            my %ns = ( 'pxml' => _NS_PHYLOXML_ );
            update_meta( $taxon, 'pxml:code' => $code, %ns );
            update_meta( $taxon, 'pxml:scientific_name' => $map{$key}->[0], %ns );
        }
        else {
            warn 'wtf:', $key;
        }
    }
    else {
        warn 'wtf: ', $name;
    }

}

{
    open my $fh, '>', $infile or die $!;
    print $fh $project->to_xml( '-compact' => 1 );
    close $fh;
}
print unparse( '-format' => 'phyloxml', '-phylo' => $project );