#! /usr/bin/perl

use strict;
use warnings;

=head1 NAME

template - A template for Perl programs.

=head1 SYNOPSIS

cp template newprog

=head1 DESCRIPTION

blah blah blah

=head1 OPTIONS

=over 4

=item --help

Show help and exit.

=item --version

Show version and exit.

=back

=head1 AUTHOR

Pete Ratzlaff E<lt>pratzlaff@cfa.harvard.eduE<gt> November 2012

=head1 SEE ALSO

perl(1).

=cut

my $version = '0.1';

use FindBin;
use Config;
use Carp;
use Astro::FITS::CFITSIO qw( CASEINSEN );
use Chandra::Tools::Common qw( read_bintbl_cols );
use File::Copy;
use PDL;
use PDL::Graphics::PGPLOT;
use PDL::IO::Misc;
use PDL::NiceSlice;

use Getopt::Long;
my %default_opts = (
		    infile => './HRCI_QE_Jan10/hrciD1999-07-22qeN0007prime_renorm.fits',
		    outfile => 'hrciD1999-07-22qeN0010.fits',
		    );
my %opts = %default_opts;
GetOptions(\%opts,
	   'help!', 'version!', 'debug!',
	   'infile=s', 'outfile=s',
	   ) or die "Try --help for more information.\n";
if ($opts{debug}) {
  $SIG{__WARN__} = \&Carp::cluck;
  $SIG{__DIE__} = \&Carp::confess;
}
$opts{help} and _help();
$opts{version} and _version();

my ($infile, $outfile) = @opts{qw( infile outfile )};

print STDERR "cp $infile -> $outfile\n";
copy($infile, $outfile) or die $!;

my $s = 0;
my $fptr = Astro::FITS::CFITSIO::open_file($outfile, Astro::FITS::CFITSIO::READWRITE(), $s);

finish_header($fptr, $s);

$fptr->movabs_hdu(2, Astro::FITS::CFITSIO::BINARY_TBL(), $s);

my $hdr = $fptr->read_header();
my ($energy, $qe) = read_bintbl_cols($fptr, qw( energy qe ));

my $lam = 12.39854 / $energy;

my ($ratio_wav, $ratio_neg, $ratio_pos) = rcols('../N0009/new_old_ratio.txt', 0..2, { lines => '2:-1' });

# the $ratio_neg and $ratio_pos are typically within 0.5%, so just use
# the average to make everything easier
my $ratio = 0.5 * ($ratio_neg + $ratio_pos);

#$ratio /= 0.901023;
$ratio /= 0.85;

$qe /= interpol($lam, $ratio_wav, $ratio);

my $qe_colnum;
$fptr->get_colnum(CASEINSEN, 'qe', $qe_colnum, $s);
$fptr->write_col(Astro::FITS::CFITSIO::TDOUBLE(), $qe_colnum, 1, 1, $qe->nelem, $qe->double->get_dataref, $s);

finish_header($fptr, $s);

$fptr->close_file($s);
check_status($s);

exit 0;

sub _help {
  exec("$Config{installbin}/perldoc", '-F', $FindBin::Bin . '/' . $FindBin::RealScript);
}

sub _version {
  print $version,"\n";
  exit 0;
}

sub check_status {
  my $s = shift;
  if ($s != 0) {
    my $txt;
    Astro::FITS::CFITSIO::fits_get_errstatus($s,$txt);
    carp "CFITSIO error: $txt";
    return 0;
  }

  return 1;
}

sub finish_header {
  my $fptr = shift;
  $fptr->update_key_str('creator', $FindBin::Bin . '/' . $FindBin::RealScript, undef, $_[0]);
  $fptr->write_date($_[0]);
  $fptr->write_chksum($_[0]);
}
