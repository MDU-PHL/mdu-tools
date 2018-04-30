#!/usr/bin/env perl
use strict;
use LWP::Simple;

# USAGE:
#
#   mkdir spades
#   cd spades
#   spades_download_all_versions.pl > Makefile
#
#   make list   # see versions
#
#   make              # download all one by one, for Linux
#   make ARCH=Darwin  # download all one by one, for MacOS
#   make -j           # download all in parallel
#   make 3.8.1        # download a specific version
#
#   3.8.1/bin/spades.py --help
#
#   make clean  # remove all .tgz files
#

my $ARCH = "Linux";
my $ROOT = "http://cab.spbu.ru/files";

my %seen;
my %ver;
print STDERR "Reading: $ROOT\n";
my $index = get($ROOT) or die "Can't read index: $ROOT";
while ($index =~ m/(release(\d+\.\d+.\d+))/g) {
  my($rel,$v) = ($1,$2);
  next if $seen{$v}++;
  if ($v !~ m/^2\.[123]/) {
    $ver{$v} = [ "$ROOT/$rel", "SPAdes-$v-\$(ARCH).tar.gz" ];
  }
  else {
    print STDERR "Skipping $rel which has no binaries.\n";
  }
}

print STDERR "Making Makefile\n";

my @ver = reverse sort { $a <=> $b } keys %ver;
my @clean;

print "ARCH=Linux # use Darwin for macOS\n\n";

print ".DELETE_ON_ERROR:\n";
print ".PHONY: all list clean\n\n";
print "all: @ver\n\n";
print "list:\n\t\@echo @ver | tr ' ' '\\n'\n\n";

for my $ver (reverse sort { $a <=> $b } keys %ver) {
  my($url,$fname) = @{$ver{$ver}};
  print "$ver: $fname\n";
  print "\tmkdir \$\@\n";
  print "\ttar --strip-components 1 -C \$\@ -x -f '$fname'\n\n";
  print "$fname:\n";
  print "\twget $url/$fname\n\n";
  push @clean, $fname;
}

print "clean:\n\t\$(RM) @clean\n\n";
print STDERR "Done.\n";
