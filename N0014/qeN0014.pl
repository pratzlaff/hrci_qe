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

Pete Ratzlaff E<lt>pratzlaff@cfa.harvard.eduE<gt> June 2021

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
use PDL::IO::Misc;
use PDL::NiceSlice;
use File::Path 'make_path';
use Data::Dumper;

use Getopt::Long;
my %default_opts = (
		    infile => '../N0010/qe/hrciD1999-07-22qeN0010.fits',
		    indir => './hrciqe',
		    outdir => './qe',
		    outver => 'N0014',
		    );
my %opts = %default_opts;
GetOptions(\%opts,
	   'help!', 'version!', 'debug!',
	   'infile=s', 'indir=s', 'outdir=s', 'outver=s',
	   ) or die "Try --help for more information.\n";
if ($opts{debug}) {
  $SIG{__WARN__} = \&Carp::cluck;
  $SIG{__DIE__} = \&Carp::confess;
}
$opts{help} and _help();
$opts{version} and _version();

make_path($opts{outdir});

# get list of FITS files and dates
my ($fits, $dates) = fits_files($opts{indir});

# construct cv[se]d values
my $cvsd = construct_cvsd($dates);

for my $i (0..$#{$fits}) {
  print join("\t",
	     $fits->[$i],
	     $dates->[$i],
	     $cvsd->[$i],
	     "\n");
  create_file($cvsd->[$i], $fits->[$i]);
}

exit 0;

sub modify_qe {
  my ($fptr, $fits) = @_;

  my $s=0;

  my $nrows;
  $fptr->get_num_rows($nrows, $s);
  $fptr->delete_rows(1, $nrows, $s);

  my ($newenergy, $newqe) = read_bintbl_cols($fits.'[1]', qw( energy newqe ));

  $newenergy = $newenergy->flat;
  $newqe = $newqe->flat;

  my ($energy_colnum, $qe_colnum);
  $fptr->get_colnum(CASEINSEN, 'energy', $energy_colnum, $s);
  $fptr->get_colnum(CASEINSEN, 'qe', $qe_colnum, $s);
  $fptr->write_col(Astro::FITS::CFITSIO::TDOUBLE(), $energy_colnum, 1, 1, $newenergy->nelem, $newenergy->double->get_dataref, $s);
  $fptr->write_col(Astro::FITS::CFITSIO::TDOUBLE(), $qe_colnum, 1, 1, $newqe->nelem, $newqe->double->get_dataref, $s);
  check_status($s) or die;
}

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

sub fits_files {
  my $dir = shift;
  my @files = grep { not /6264/ } glob("$dir/hrciqe_*.fits");
  my @dates = map { +(/(\d{4}\.\d{2})/)[0]*1.0 } @files;
  my @sorti = sort { $dates[$a] <=> $dates[$b] } 0..$#dates;
  return [ @files[@sorti] ], [ @dates[@sorti] ];
}

sub construct_cvsd {
  my $dates = shift;
  my @cvsd;

  for my $i (0..$#{$dates}) {

    if ($i==0) { push @cvsd, '1999-07-29'; }
    else {
      if ($dates->[$i] eq '2024.72') {
	push @cvsd, '2024-09-20';
      }
      else {
	push @cvsd, sprintf("%04d-%02d-%02d", frac2ymd(0.5*($dates->[$i]+$dates->[$i-1])));
      }
    }

  }

  return \@cvsd;
}

sub frac2ymd {
  my $frac = shift;
  my $y = int($frac);
  my $dn = int(366*($frac - $y)); # leap year does not concern us
  my ($m, $d) = dn2md($dn);
  return $y, $m, $d;
}

# return month and day given day number
sub dn2md {
  my $dn = shift;

  my ($sum, @month_days)=(0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  foreach (0..$#month_days) {
    if (($sum += $month_days[$_]) >= $dn) {
      return ($_+1,$dn-($sum-$month_days[$_]));
    }
  }
  confess "problems!!!";
}

sub update_dates {
  my ($fptr, $cvsd, $s) = @_;
  check_status($s) or die;

  # special case at the first HV change, where obsids 24941 and 62639
  # were both taken on 2021-02-16, but the latter with the new HV

  my $cvst = '00:00:00';
  $cvst = '13:09:07' if $cvsd eq '2021-02-16';
  $cvst = '12:00:00' if $cvsd eq '2024-09-20';

  $fptr->update_key_str('cvsd0001', $cvsd.'T'.$cvst, undef, $s);
  $fptr->update_key_str('cvst0001', $cvst, undef, $s);

  return $s;
}

sub create_file {
  my ($cvsd, $fitsfile) = @_;

  my $infile = $opts{infile};
  my $outfile = sprintf '%s/hrciD%sqe%s.fits', $opts{outdir}, $cvsd, $opts{outver};

  copy($opts{infile}, $outfile) or die $!;

  my $s = 0;
  my $fptr = Astro::FITS::CFITSIO::open_file($outfile, Astro::FITS::CFITSIO::READWRITE(), $s);

  update_dates($fptr, $cvsd, $s);
  finish_header($fptr, $s);

  $fptr->movabs_hdu(2, Astro::FITS::CFITSIO::BINARY_TBL(), $s);
  check_status($s) or die;

  modify_qe($fptr, $fitsfile);

  update_dates($fptr, $cvsd, $s);
  finish_header($fptr, $s);

  $fptr->close_file($s);
  check_status($s);
}
