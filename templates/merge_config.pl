#!/usr/bin/env perl

use strict;
use YAML qw/LoadFile DumpFile/;
use Hash::Merge;
use File::Basename;
use File::Spec::Functions;

die "needs three parameters!!!!\n" if scalar @ARGV != 3;

my $config_hash = LoadFile($ARGV[0]);
my $sample_hash = LoadFile($ARGV[1]);

my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
my $merged = $merger->merge($sample_hash, $config_hash);

my $outfile = catfile(dirname $ARGV[1], $ARGV[2].'.yml' );
DumpFile($outfile, $merged);

