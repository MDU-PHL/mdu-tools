#!/usr/bin/env perl

# Torsten Seemann
# 2018-09-03

use strict;
use Getopt::Std;
use Data::Dumper;
use File::Basename;

my $EXE = basename($0);
my $VERSION = 0.2;

sub VERSION_MESSAGE {
  my($fh) = @_;
  print $fh "$EXE $VERSION\n";
}

sub HELP_MESSAGE {
  my($fh) = @_;
  #print $fh Dumper(\@_);
  print $fh map { "$_\n" }
    "SYNOPSIS",
    "  Print character frequencies of each contig in FASTA file",
    "USAGE",
    "  $EXE [options] file.fasta [ file2.fasta ... ]",
    "OPTIONS",
    "  -h   This help",
    "  -V   Print version and exit",
    "  -c   Output in CSV instead of TSV format",
    "  -p   Print percent(%) rather than absolute count",
    "  -g   Treat file as a single sequence; give global stats",
    "  -q   Quiet mode; don't output progess",
    "END"
  ;
}

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %opt;
getopts('gpcqhV', \%opt);

$opt{'V'} and do { VERSION_MESSAGE(\*STDOUT); exit(0) };
$opt{'h'} and do { HELP_MESSAGE(\*STDOUT); exit(0) };

my $SEP = $opt{'c'} ? ',' : "\t";

my @id;
my %len;
my %freq;
my $id = $ARGV[0] || 'Total';

while (<ARGV>) {
  chomp;
  if (m/^>(\S+)/) {
    print STDERR "Counting: $1\n" unless $opt{'q'};
    if ($opt{'g'}) {
      push @id, $id unless @id;
    }
    else {
      $id = $1;
      push @id, $id;
    }
  }
  else {
    for my $c (split m//, $_) {
      $freq{$c}{$id}++;
      $len{$id}++;
    }
  }
}

my @char = sort keys %freq;
print join($SEP, "SEQUENCE", "LENGTH", @char), "\n";  # header

for my $id (@id) {
  my @freq = map { $freq{$_}{$id} || '0' } @char;
  @freq = map { sprintf "%.3f", $_ * 100.0 / $len{$id} } @freq if $opt{'p'};
  print join($SEP, $id, $len{$id}, @freq),"\n";
}



