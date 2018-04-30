#!/usr/bin/env perl
use strict;
use LWP::Simple;

my $ROOT = "http://cab.spbu.ru/files";

my %ver;
print STDERR "Reading: $ROOT\n";
my $index = get($ROOT) or die "Can't read index: $ROOT";
while ($index =~ m/(release(\d+\.\d+.\d+))/g) {
  $ver{$2} = [ "$ROOT/$1", "SPAdes-$2-Linux.tar.gz" ];
}

print STDERR "Making Makefile\n";
my @ver = reverse sort { $a <=> $b } keys %ver;
print "all: @ver\n";
for my $ver (reverse sort { $a <=> $b } keys %ver) {
  my($url,$fname) = @{$ver{$ver}};
  print "$ver: $fname\n";
  print "mkdir \$\@\n";
  print "\ttar --strip-components 1 -C \$\@ -x -f '$fname'\n\n";
  print "$fname:\n";
  print "\twget $url/$fname\n";
}
print STDERR "Done.\n";

# this is not used - was just for development.
__DATA__
[DIR] release2.1.0/                  21-Nov-2016 16:35    -   
[DIR] release2.2.0/                  21-Nov-2016 16:35    -   
[DIR] release2.2.1/                  21-Nov-2016 16:36    -   
[DIR] release2.3.0/                  21-Nov-2016 16:36    -   
[DIR] release2.4.0/                  21-Nov-2016 16:36    -   
[DIR] release2.5.0/                  21-Nov-2016 16:36    -   
[DIR] release2.5.1/                  21-Nov-2016 16:36    -   
[DIR] release3.0.0/                  21-Nov-2016 16:36    -   
[DIR] release3.1.0/                  21-Nov-2016 16:36    -   
[DIR] release3.1.1/                  21-Nov-2016 16:36    -   
[DIR] release3.10.0/                 30-Jan-2017 04:58    -   
[DIR] release3.10.1/                 01-Mar-2017 04:33    -   
[DIR] release3.11.0/                 04-Sep-2017 11:24    -   
[DIR] release3.11.1/                 29-Sep-2017 17:19    -   
[DIR] release3.5.0/                  21-Nov-2016 16:36    -   
[DIR] release3.6.0/                  21-Nov-2016 16:36    -   
[DIR] release3.6.1/                  21-Nov-2016 16:36    -   
[DIR] release3.6.2/                  21-Nov-2016 16:36    -   
[DIR] release3.7.0/                  21-Nov-2016 16:36    -   
[DIR] release3.7.1/                  21-Nov-2016 16:36    -   
[DIR] release3.8.0/                  21-Nov-2016 16:36    -   
[DIR] release3.8.1/                  21-Nov-2016 16:36    -   
[DIR] release3.8.2/                  21-Nov-2016 16:36    -   
[DIR] release3.9.0/                  21-Nov-2016 16:37    -   
[DIR] release3.9.1/                  04-Dec-2016 04:18    - 

http://cab.spbu.ru/files/release3.11.1/SPAdes-3.11.1-Linux.tar.gz

http://cab.spbu.ru/files/release3.7.1/SPAdes-3.7.1-Linux.tar.gz

