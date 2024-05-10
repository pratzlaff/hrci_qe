#! /usr/bin/perl

use strict;
use warnings;

use PDL::Graphics::PGPLOT;
use Chandra::Tools::Common qw/read_bintbl_cols/;

my ($f1, $f2) = @ARGV;

my ($qe1, $e1) = read_bintbl_cols($f1.'[1]', qw/newqe energy/);
my ($qe2, $e2) = read_bintbl_cols($f2.'[1]', qw/newqe energy/);
my $ratio = $qe2/$qe1;
line $e1, $ratio, { border => { type => 'rel', value => 0.1 }}; #, xrange => [0.62, .63] };
print(join("\t", $ratio->minmax), "\n");
