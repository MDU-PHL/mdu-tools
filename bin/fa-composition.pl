#!/usr/bin/env perl

# Torsten Seemann
# 2018-09-03

use strict;
use Getopt::Std;
use Data::Dumper;
use File::Basename;
use List::Util qw(uniq);

my $EXE = basename($0);
my $VERSION = 0.4;

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
    "  -f   Treat each input file as a single sequence; give per file stats",
    "  -g   Treat inputs as a single sequence; give global stats",
    "  -i   Case insensitive counting",
    "  -s   Use whole > line as ID, don't stop at first space",
    "  -n   Don't print header",
    "  -q   Quiet mode; don't output progess",
    "END"
  ;
}

sub err { print STDERR "ERROR: @_\n"; exit(1); }

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %opt;
getopts('gpcsqhfinV', \%opt);

$opt{'V'} and do { VERSION_MESSAGE(\*STDOUT); exit(0) };
$opt{'h'} and do { HELP_MESSAGE(\*STDOUT); exit(0) };

my $SEP = $opt{'c'} ? ',' : "\t";

my %seen;
my @id;
my %len;
my %freq;
my $id = $ARGV[0] || 'Total';
my $id_regex = $opt{'s'} ? qr/^>(.*)/ : qr/^>(\S+)/;

for my $argv (@ARGV) {
  open my $FASTA, '<', $argv;
  while (<$FASTA>) {
    chomp;
    if ($_ =~ $id_regex) {
      print STDERR "Counting: $argv $1\n" unless $opt{'q'};
      if ($opt{'g'}) {
        push @id, $id unless @id;
      }
      elsif ($opt{'f'}) {
        $id = $argv;
      }
      else {
        $id = $1;
        $seen{$id}++ >= 1 and err("Duplicate ID '$id'. Try using -s ?");
        push @id, $id;
      }
    }
    else {
      $_ = uc($_) if $opt{'i'};
      for my $c (split m//, $_) {
        $freq{$c}{$id}++;
        $len{$id}++;
      }
    }
  }
}

# FIXME - put A,T C,G, N  in front of sorted list?
my @char = uniq(qw(A T C G N), sort keys %freq);
print join($SEP, "ID", "LENGTH", @char), "\n" unless $opt{'n'};

for my $id (@id) {
  my @freq = map { $freq{$_}{$id} || '0' } @char;
  @freq = map { sprintf "%.3f", $_ * 100.0 / $len{$id} } @freq if $opt{'p'};
  print join($SEP, $id, $len{$id}, @freq),"\n";
}

