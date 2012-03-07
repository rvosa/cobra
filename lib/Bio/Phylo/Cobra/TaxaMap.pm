package Bio::Phylo::Cobra::TaxaMap;
use strict;
use warnings;
our $AUTOLOAD;

my %keys = (
	'label'      => 0,
	'binomial'   => 1,
	'taxonID'    => 2,
	'code'       => 3,
	'namebankID' => 4,
	'tolID'      => 5,
);

=pod

=head1 GETTER/SETTERS

=over

=item $map->binomial($label, [$binomial])

=item $map->namebankID($label, [$namebankID])

=item $map->taxonID($label, [$taxonID])

=item $map->tolID($label, [$tolID])

=item $map->code($label, [$code])

=back

=head1 QUERIES

=over

=item $map->get_x_for_y()

x and y are both one of label, binomial, namebankID, taxonID, tolID, code

=item $map->get_all_xs()

=item $map->get_distinct_xs()

=back

=head1 METHODS

=over

=item to_csv()

=item as_2d()

=back

=cut


sub new {
	my $package = shift;
	my $file = shift;
	my %self;
	open my $fh, '<', $file or die $!;
	while(<$fh>) {
		chomp;
		my @fields = split /,/, $_;
		my $key = shift @fields;
		$self{$key} = \@fields;
	}
	return bless \%self, $package;
}

sub as_2d {
	my $self = shift;
	my @result;
	for my $key ( sort { $a cmp $b } keys %{ $self } ) {
		push @result, [ $key, @{ $self->{$key} } ];
	}
	return @result;
}

sub to_csv {
	my $self = shift;
	my $string = '';
	for my $row ( $self->as_2d ) {
		$string .= join ',', @{ $row };
		$string .= "\n";	
	}
	return $string;
}

sub AUTOLOAD {
	my $method = $AUTOLOAD;
	$method =~ s/.*://;
	if ( exists $keys{$method} ) {
		my $self = shift;
		my $label = shift;
		my $value = shift;
		if ( $value ) {
			$self->{$label}->[$keys{$method}] = $value;
		}
		return $self->{$label}->[$keys{$method}];
	}
	elsif ( $method =~ m/get_([^_]+)_for_([^_]+)/ ) {
		my ( $wanted, $key ) = ( $1, $2 );
		my $self = shift;
		my $value = shift;
		my @result;
		for my $row ( $self->as_2d ) {
			if ( $row->[$keys{$key}] && $row->[$keys{$key}] eq $value ) {
				push @result, $row->[$keys{$wanted}];
			}
		}
		return wantarray ? @result : $result[0];
	}
	elsif ( $method =~ m/get_all_([^_]+)s/ ) {
		my $field = $1;
		my $self = shift;
		my @result;
		for my $row ( $self->as_2d ) {
			push @result, $row->[$keys{$field}];
		}
		return @result;
	}
	elsif ( $method =~ m/get_distinct_([^_]+)s/ ) {
		my $field = $1;
		my $self = shift;
		my %result;
		for my $row ( $self->as_2d ) {
			my $value = $row->[$keys{$field}];
			$result{ $value } = 1 if $value;
		}
		return sort { $a cmp $b } keys %result;
	}
}