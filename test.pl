#! /usr/bin/perl
use strict;
use warnings;

use PDL;
use PDL::Graphics::PGPLOT;
use Chandra::Tools::Common qw/ read_bintbl_cols /;

my $f1 = './N0011/qe/hrciD2017-08-20qeN0011.fits';
my $f2 = './N0013/qe/hrciD2021-02-16qeN0013.fits';

my ($e1, $qe1) = read_bintbl_cols($f1.'[1]', qw/ energy qe / );
my ($e2, $qe2) = read_bintbl_cols($f2.'[1]', qw/ energy qe / );

dev '/xs', 1, 3;

my $i = which($e1 > 0.5);

line $e1, $qe1, { border => 0.1 };
line $e2, $qe2, { border => 0.1 };
line $e1->index($i), $qe1->index($i)/$qe2->index($i), { border => 0.1 };
