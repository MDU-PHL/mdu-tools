#!/usr/bin/env perl
use strict;
use LWP::Simple;

# USAGE:
#
#   mkdir spades
#   cd spades
#   spades_download_all_versions.pl > Makefile
#   make        # download all one by one
#   make -j     # download all in parallel
#   make 3.8.1  # download a specific version
#   3.8.1/bin/spades.py --help


my $ARCH = "Linux";
my $ROOT = "http://cab.spbu.ru/files";

my %ver;
print STDERR "Reading: $ROOT\n";
my $index = get($ROOT) or die "Can't read index: $ROOT";
while ($index =~ m/(release(\d+\.\d+.\d+))/g) {
  $ver{$2} = [ "$ROOT/$1", "SPAdes-$2-$ARCH.tar.gz" ];
}

print STDERR "Making Makefile\n";
my @ver = reverse sort { $a <=> $b } keys %ver;
print ".DELETE_ON_ERROR:\n\n";
print "all: @ver\n\n";
for my $ver (reverse sort { $a <=> $b } keys %ver) {
  my($url,$fname) = @{$ver{$ver}};
  print "$ver: $fname\n";
  print "\tmkdir \$\@\n";
  print "\ttar --strip-components 1 -C \$\@ -x -f '$fname'\n\n";
  print "$fname:\n";
  print "\twget $url/$fname\n\n";
}
print STDERR "Done.\n";
