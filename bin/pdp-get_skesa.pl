#!/usr/bin/env perl
use strict;
use File::Basename;
use Data::Dumper;
use File::Which;

#echo srapath -P -f names SRR498276.realign
#echo vdb-dump -T REFERENCE -f fasta2 https://sra-download.ncbi.nlm.nih.gov/traces/sra48/SRZ/000498/SRR498276/SRR498276.realign

my $VERSION = "0.0.1";
my $EXE = basename($0);
sub msg { print STDERR "@_\n"; }
sub err { msg("ERROR:", @_); exit(-1); }

@ARGV or err("Please provide some SRA accession numbers");;
$ARGV[0] =~ m/^-h/ and show_help(0);
$ARGV[0] =~ m/^-v/i and show_version();

for my $tool ('srapath', 'vdb-dump') {
  my $path = which($tool);
  $path ? msg("Found $tool: $path") : err("Please install tool '$tool'");
}

for my $id (@ARGV) {
  $id =~ m/^[SED]RR\d+$/ or err("Malformed accession '$id'");
  my $fa = "$id.fa";
  if (-s $fa) {
    msg("Assembly '$fa' already exists, skipping.");
    next;
  }
  msg("Getting SRA path for:", $id);
  my($uri) = qx(srapath -P -f names $id.realign);
  chomp $uri;
  if ($uri) {
    msg("Downloading $id contigs to: $fa");
    system("vdb-dump -T REFERENCE -f fasta2 $uri | sed 's/^>/>${id}_/' > $fa");
    my $size = -s $fa;
    msg("Wrote $size bytes to $fa");
  }
  else {
    msg("No SKESA assembly for $id");
  }
}

sub show_help {
  msg("SYNOPIS\n  Download NCBI SKESA assembly of SRA sample in PDP");
  msg("USAGE\n  $EXE [SED]RRnnnnnnn");
  msg("AUTHOR\n  Torsten Seemann");
  exit($_[0]);
}

sub show_version {
  msg("$EXE $VERSION");
  exit(0);
}

sub slurp {
  my($fname) = @_;
  open my $fh, '<', $fname;
  my @lines = <$fh>;
  chomp @lines;
  close $fh;
  return @lines;
}
