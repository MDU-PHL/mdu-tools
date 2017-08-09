#!/usr/bin/env perl
use strict;
use warnings;
#use IO::Zlib;

# >sequence16|kraken:taxid|32630  Adapter sequence
# >gi|12233456667|

@ARGV >= 2 or die "Usage: $0 <taxid> <file.gbk[.gz]> ...";

my $taxid = shift @ARGV;
$taxid =~ m/^(\d+)$/ or die "First parameter must be a numeric taxonid eg. 9606 for human";

my $wrote=0;

for my $fasta (@ARGV) {
  print STDERR "Converting: $fasta\n";
  open IN, "-|", "gzip -c -d -f \Q$fasta\E" or die "Could not open $fasta";
  while (<IN>) {
    if (m/^>(\S+)/) {
      print ">$1|kraken:taxid|$taxid\n";
      $wrote++;
    }
    else {
      print;
    }
  }
  close IN;
}
print STDERR "Wrote $wrote sequences.\n";
