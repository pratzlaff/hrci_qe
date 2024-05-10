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

Pete Ratzlaff E<lt>pratzlaff@cfa.harvard.eduE<gt> April 2018

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

use Getopt::Long;
my %default_opts = (
		    infile => '../N0010/hrciD1999-07-22qeN0010.fits',
		    shv0file => '../../hrcs_qe/N0014/hrcsD1999-07-22qeN0014.fits',
		    shv1file => '../../hrcs_qe/N0014/hrcsD2012-03-29qeN0014.fits',
		    outdir => './qe/b',
		    outver => 'N0011b',
		    );
my %opts = %default_opts;
GetOptions(\%opts,
	   'help!', 'version!', 'debug!',
	   'infile=s', 'outdir=s',
	   ) or die "Try --help for more information.\n";
if ($opts{debug}) {
  $SIG{__WARN__} = \&Carp::cluck;
  $SIG{__DIE__} = \&Carp::confess;
}
$opts{help} and _help();
$opts{version} and _version();

my %qe_base = setup_qe_base();
#use PDL::Graphics::PGPLOT;
#line $qe_base{energy}->log10, $qe_base{qe_shv0}/$qe_base{qe_i}, { border => 1 };
#exit;

make_path($opts{outdir});

my ($y, $corr) = rcols 'adjust_hrciQE_fromhrcs.rdb', 0, 2, { lines => '14:' };
my $baseline = $corr->where($y<2011.5)->median;

# specific files for years 2011 through the year after the final observation
my $years = sequence(int($y->at(-1)+1)-2010) + 2011.5;
#my $factors = interpol($years, $y, $corr) / $baseline;
my $factors = interpol($years, $y, $corr);
print "years=",$years, "\n";
print "factors=",$factors, "\n";

my %factors;
@factors{$years->list} = $factors->list;

for my $y (undef, $years->list) {
  generate_file($opts{infile}, $y);
}

sub generate_file {
  my ($infile, $year) = @_;

  my $cvsd = '1999-07-22';
  my ($cved, $factor);

  if (defined $year) {
    $cvsd = sprintf("%d-01-01", $year);
    $cved = sprintf("%d-01-01", $year+1) unless $year == $years->at(-1);
    $factor = $factors{$year};
  }
  else {
    $cved = sprintf("%d-01-01", $years->at(0));
    $factor = $baseline;
  }

  my $outfile = sprintf("%s/hrciD%sqe%s.fits", $opts{outdir}, $cvsd, $opts{outver});

  print STDERR "cp $infile -> $outfile\n";
  copy($infile, $outfile) or die $!;

  my $s = 0;
  my $fptr = Astro::FITS::CFITSIO::open_file($outfile, Astro::FITS::CFITSIO::READWRITE(), $s);

  finish_header($fptr, $s);

  $fptr->movabs_hdu(2, Astro::FITS::CFITSIO::BINARY_TBL(), $s);
  check_status($s) or die;

  modify_qe($fptr, $factor, $year);

  $fptr->update_key_str('cvsd0001', $cvsd.'T00:00:00', undef, $s);
  $fptr->update_key_str('cvst0001', '00:00:00', undef, $s);

  if (defined $cved) {
    $fptr->update_key_str('cved0001', $cved.'T00:00:00', undef, $s);
    $fptr->update_key_str('cvet0001', '00:00:00', undef, $s);
  }
  else {
    check_status($s) or die;
    $fptr->delete_key('cved0001', $s=0);
    $fptr->delete_key('cvet0001', $s=0);
    $s=0;
  }

  finish_header($fptr, $s);
  $fptr->close_file($s);
  check_status($s);

}

sub read_i_qe {
  my $file = shift;
  my ($energy, $e) = read_bintbl_cols($file, qw/energy qe/, { extname => 'axaf_qe' });
  return $energy, $e;
}

sub read_s_qe {
  my $file = shift;
  my ($regionid, $energy, $e) = read_bintbl_cols($file, qw/regionid energy qe/, { extname => 'axaf_qe2' });
  my $i = which($regionid == 201)->at(0);
  return $energy->slice(",($i)"), $e->slice(",($i)");
}

sub modify_qe {
  my ($fptr, $factor, $year) = @_;
  my $hdr = $fptr->read_header();
  my ($energy, $qe) = read_bintbl_cols($fptr, qw( energy qe ));

  my $index = which($energy <= 0.626);

  # pre 2012-03-29
  if (!defined($year) or $year < 2012+88/365) {
    (my $tmp = $qe->index($index)) .= $qe_base{qe_shv0}->index($index) * $factor;
  }
  else {
    (my $tmp = $qe->index($index)) .= $qe_base{qe_shv1}->index($index) * $factor;
  }

  my $s=0;
  my $qe_colnum;
  $fptr->get_colnum(CASEINSEN, 'qe', $qe_colnum, $s);
  $fptr->write_col(Astro::FITS::CFITSIO::TDOUBLE(), $qe_colnum, 1, 1, $qe->nelem, $qe->double->get_dataref, $s);
  check_status($s) or die;
}

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

sub setup_qe_base {
  my %r;

  @r{qw/energy qe_i/} = read_i_qe($opts{infile});

  for my $s (qw/ hv0 hv1 /) {
    my ($energy, $qe) = read_s_qe($opts{"s${s}file"});
    $r{"qe_s${s}"} = interpol($r{energy}, $energy, $qe);
  }

  return %r;
}
