#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Spec;

my %seen_path;
my %seen_exe;
my $count;

for my $p ( File::Spec->path() ) {
  next if $seen_path{$p}++;
#  print STDERR "Parsing: $p\n";
  opendir(my $dh, $p) or next;
  while (readdir $dh) {
    next if m/^\./;
    next if m/~$/;
#    print STDERR "# $p/$_\n";
    next if $seen_exe{$_}++;
    if (-r "$p/$_" && !-d _ && -x _) {
      print "hash -p '$p/$_' '$_'\n";  
      $count++;
    }
  }
  closedir $dh;
}
#print STDERR "Hashed $count executables.\n";
