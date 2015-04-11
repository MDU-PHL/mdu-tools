#!/usr/bin/env perl
use strict;
use warnings;

#-------------------------------------------------------------------
# libraries

use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::RealBin/../perl5";
use MDU qw(msg err);

#-------------------------------------------------------------------
# command line

my $verbose = 0;
my $quiet   = 0;
my $id      = '';

sub usage {
  print <<"USAGE";
Usage: 
  $FindBin::RealScript [options]
Options:
  --help	This help
  --verbose	Extra debugging output
  --quiet	No screen output
USAGE
}

@ARGV or usage();

GetOptions(
  "help"     => \&usage,
  "verbose"  => \$verbose,
  "quiet"    => \$quiet,
  "id=s"     => \$id,
) 
or usage();

MDU->quiet($quiet);

#-------------------------------------------------------------------
# main script

msg("ARGV = @ARGV");
msg("Done.");

