#!/usr/bin/perl -w
use strict;
my $i = 1;
while(<>) {
    print $_ !~ /;$/ ? $_ . ')n' . $i++ : $_ for split /\)/, $_;
}

