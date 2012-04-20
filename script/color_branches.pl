#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::Treedrawer;
use Bio::Phylo::Cobra::TaxaMap;
use Bio::Phylo::IO 'parse_tree';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my $param   = 'omega3';
my $pvalue  = 'Corrected p-value';
my $verbose = DEBUG;
my ( $csv, $nexus, $hyphy, %defines );
GetOptions(
	'csv=s'    => \$csv,
	'nexus=s'  => \$nexus,
	'hyphy=s'  => \$hyphy,
	'param=s'  => \$param,
	'verbose+' => \$verbose,
	'define=s' => \%defines,
);

# instantiate logger object
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbose,
	'-class' => 'main',
);

# instantiate taxa map
my $map = Bio::Phylo::Cobra::TaxaMap->new($csv);

# parameterize factory to create drawtree
my $fac = Bio::Phylo::Factory->new(
	'node' => 'Bio::Phylo::Forest::DrawNode',
	'tree' => 'Bio::Phylo::Forest::DrawTree',
);

# parse tree
my $tree = parse_tree(
	'-format'  => 'nexus',
	'-file'    => $nexus,
	'-factory' => $fac,
);

# parse BranchSiteREL csv output
my %bsr = parse_bsr($hyphy);
%bsr = normalize_param( $param, %bsr );

# color branches by param val
$tree->visit(sub{
	my $node  = shift;
	my $label = uc $node->get_name;
	
	# set branch color
	my $value = $bsr{$label}->{$param};
	$log->info("$label => $value");
	my $color = make_color($value);
	$node->set_branch_color($color);
	
	# set significance level and binomial name
	my $p = $bsr{$label}->{$pvalue};
	my $name = $node->is_terminal ? $map->get_binomial_for_phylip($label) : '';
	if ( $p <= 0.01 ) {
		$node->set_name($name . ' **');
	}
	elsif ( $p <= 0.05 && $p > 0.01 ) {
		$node->set_name($name . ' *');
	}
	else {
		$node->set_name($name);
	}
	
	# set font face
	$node->set_font_face('Verdana');
	
	# set font style
	$node->set_font_style('Italic');
	
	# make venomous snakes boldface
	if ( $map->get_venom_for_phylip($label) ) {
		$node->set_font_color('red');
	}

});

# process tree drawer defines
my %args;
for my $key ( keys %defines ) {
	if ( $defines{$key} eq 'auto' ) {
		my $height = scalar @{ $tree->get_terminals } * 20;
		$args{'-height'} = $height;
	}
	else {
		$args{"-${key}"} = $defines{$key};
	}
}

# print tree
print Bio::Phylo::Treedrawer->new( %args, '-tree' => $tree )->draw;

# parse CSV output from BranchSiteREL
# service on datamonkey
sub parse_bsr {
	my $file = shift;
	my ( %result, @header );
	open my $fh, '<', $file or die $!;
	LINE: while(<$fh>) {
		chomp;
		if ( not @header ) {
			@header = split /,/, $_;
			shift @header;
			next LINE;
		}
		my @line  = split /,/, $_;
		my $label = shift @line;
		my %record;
		for my $i ( 0 .. $#header ) {
			$record{$header[$i]} = $line[$i];
		}
		$result{$label} = \%record;
	}
	return %result;
}

# scalas column to values between 0 and 255
sub normalize_param {
	my ( $param, %bsr ) = @_;
	my $highest = 0;
	for my $label ( keys %bsr ) {
		my $value = $bsr{$label}->{$param};
		$highest = $value if $value > $highest;
	}
	my $scale = $highest / 255;
	for my $label ( keys %bsr ) {
		my $value = $bsr{$label}->{$param};
		$bsr{$label}->{$param} = $value / $scale;
	}
	return %bsr;
}

# turns a single number between 0 and 255 into an
# RGB hex code between blue and ref
sub make_color {
	my $value = shift;
	my $red = sprintf '%0X', $value;
	$red = "0${red}" if length($red) == 1;
	my $green = '00';
	my $blue = sprintf '%0X', 255 - $value;
	$blue = "0${blue}" if length($blue) == 1;
	return "#${red}${green}${blue}";
}