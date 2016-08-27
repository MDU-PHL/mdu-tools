#!/usr/bin/env perl
use strict;
use warnings;
#use IO::Zlib;

# >sequence16|kraken:taxid|32630  Adapter sequence
# >gi|12233456667|

@ARGV or die "Usage: $0 <file.gbk[.gz]> ...";

my $wrote=0;
my($id, $in_seq, $taxid);

for my $gbk (@ARGV) {
  print STDERR "Converting: $gbk\n";
#  tie *IN, 'IO::Zlib', $gbk, "rb";   # using this is 5-10x slower!
  open IN, "-|", "gzip -c -d -f \Q$gbk\E" or die "Could not open $gbk";
  while (<IN>) {
    if (m/^LOCUS\s+(\S+)/) {
      $id = $1;
    }
    elsif (m/taxon:(\d+)/) {
      $taxid = $1;
    }
    elsif (m/^ORIGIN/) {
      $in_seq = 1;
      print ">$id|kraken:taxid|$taxid\n";
    }
    elsif (m{^//}) {
      $in_seq = $taxid = $id = undef;
      $wrote++;
    }
    elsif ($in_seq) {
      substr $_, 0, 10, '';
      s/\s//g;
      print $_, "\n";
    }
  }
  close IN;
}
print STDERR "Wrote $wrote sequences.\n";
