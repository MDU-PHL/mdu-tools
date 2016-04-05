#!/usr/bin/env perl
use strict;
use warnings;

#-------------------------------------------------------------------
# libraries

use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::RealBin/../perl5";
use MDU::Logger qw(msg err);
#use Regexp::Common;

#-------------------------------------------------------------------
# command line

my $verbose = 0;
my $quiet   = 0;

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
) 
or usage();

MDU::Logger->quiet($quiet);

#-------------------------------------------------------------------
# main script
my @COL = qw(FILE ORG STRAIN CTGS BP MAX_CTG GENES ASM COV TECH);
print join("\t", @COL), "\n";
for my $gbk (@ARGV) {
  msg("Trying: $gbk");
  open IN, "-|", "gzip -c -d \Q$gbk\E" or err("Could not read: $gbk");
  my %data = (FILE=>$gbk, GENES=>0, BP=>0, CTGS=>0, MAX_CTG=>0);
  while (<IN>) {
    if (m/^LOCUS\s+\S+\s+(\d+)/) {
      $data{CTGS}++;
      $data{BP} += $1;
      $data{MAX_CTG} = $1 if $1 > $data{MAX_CTG};
    }
    elsif (m/^     gene            /) {
      $data{GENES}++;
    }    
    elsif (m{/organism="(.*?)"}) {
      $data{ORG} = $1;
    }
    elsif (m{/strain="(.*?)"}) {
      $data{STRAIN} = $1;
    }
    elsif (m/Assembly Method\s+::\s+(.*)$/) {
      $data{ASM} = $1;
    }
    elsif (m/Genome Coverage\s+::\s+(.*)x$/) {
      $data{COV} = $1;
    }
    elsif (m/Sequencing Technology\s+::\s+(.*)$/) {
      $data{TECH} = $1;
    }
  }
  close IN;
  if ($data{CTGS} > 0) {
    print join("\t", map { defined($data{$_}) ? $data{$_} : '.' } @COL),"\n";
  }
}
msg("Done.");


# ##Genome-Assembly-Data-START##
# Assembly Method       :: ABYSS v. 1.3.5
# Genome Coverage       :: 25x
# Sequencing Technology :: Illumina HiSeq
# ##Genome-Assembly-Data-END##

