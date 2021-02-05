#!/usr/bin/env perl
use strict;
use LWP::Simple;

# USAGE:
#
#   mkdir blast
#   cd blast
#   blast_download_all_versions.pl > Makefile
#
#   make list   # see versions
#
#   make              # download all one by one, for Linux
#   make ARCH=Darwin  # download all one by one, for MacOS
#   make -j           # download all in parallel
#   make 3.8.1        # download a specific version
#
#   2.3.0/bin/blastn -version
#
#   make clean  # remove all .tgz files
#

# ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.31/ncbi-blast-2.2.31+-x64-linux.tar.gz

my $ARCH = $^O eq 'linux' ? "x64-linux" : "macosx-universal";
my $ROOT = "ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+";

my %seen;
my %ver;
print STDERR "Reading: $ROOT\n";
my $index = get($ROOT) or die "Can't read index: $ROOT";
while ($index =~ m/((\d+\.\d+.\d+))/g) {
  my($rel,$v) = ($1,$2);
  next if $seen{$v}++;
  print STDERR "Found: $rel\n";
  my $fname = "ncbi-blast-${v}+-${ARCH}.tar.gz";
  $ver{$v} = [ "$ROOT/${v}", $fname ];
}

print STDERR "Making Makefile\n";

my @ver = reverse sort { $a <=> $b } keys %ver;
my @clean;

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

__DATA__
2.2.31
2.3.0
2.4.0
2.5.0
2.6.0
2.7.1
2.8.1
2.9.0
