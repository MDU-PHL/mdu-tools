#!/usr/bin/env perl
use strict;
use Getopt::Std;
use File::Basename;
use Data::Dumper;

my %opt = ('f'=>'out%04d.csv', 'n'=>0, 'l'=>0);

sub msg { print STDERR "@_\n"; }
sub err { msg("ERROR:", @_); exit(-1); }
sub usage {
  my($err) = @_;
  my $fh = $err ? \*STDERR : \*STDOUT;
  my $exe = basename($0);
  print $fh <<"EOHELP";
SYNOPSIS
  Split a CSV/TSV file into verical chunks
USAGE
  $exe [options] in.csv
  $exe [options] < in.tsv
OPTIONS
  -h       Show this help and exit
  -l NUM   Break into NUM lines per file
  -n NUM   Break into NUM files
  -f FMT   Output filemame format [$opt{f}]
END    
EOHELP
  exit($err);
}

getopts('hl:n:f:', \%opt) or usage(1);
$opt{h} and usage(0);
#msg(Dumper(\%opt));

$opt{f} or err("Must provide -f FMT");
$opt{f} =~ m/%\d*d/ or err("-f must contain a %d pattern");
my $L = $opt{l} // 0;
my $N = $opt{n} // 0;
$L && $N and err("Only one of -l or -n can be used.");
(!$L && !$N) and err("Must provide one of -l or -n");
$L and msg("Will break into files of $L lines");
$N and msg("Will break into $N files");

msg("Loading input data...");
my($header,@row) = <ARGV>;
$header or err("No rows found in input");
#msg("Header: $header");
my $tab = ($header =~ tr/\t/\t/);
my $comma = ($header =~ tr/,/,/);
my $format = $tab >= $comma ? "TSV" : "CSV";
msg("Input looks like $format format");
my $cols = $tab > $comma ? 1+$tab : 1+$comma;
msg("Data appears to have $cols columns");

@row > 0 or err("No rows found in input");
msg("Found", 0+@row, "data rows");

my $lpf = $L ? $L : 1+int(@row / $N);
msg("Generating $lpf lines per file");

my $f=0;
for (my $i=0; $i < @row; $i += $lpf) {
  my $fname = sprintf $opt{f}, ++$f;
  my $j = $i + $lpf - 1;
  msg("Writing $i..$j to $fname");
  open my $fh, '>', $fname;
  print $fh $header;
  print $fh @row[ $i .. $j ];
  close $fname;
}


