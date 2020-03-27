#!/bin/perl
use strict;
use File::Basename;
use IO::Uncompress::AnyUncompress;

my $EXE = basename($0);

sub msg { print STDERR "@_\n"; }
sub err { msg("ERROR:", @_); exit(1); }

@ARGV==2 or err("Usage: $EXE R1.fq.gz R2.fq.gz");
my($R1,$R2) = @ARGV;
-r $R1 or err("Can't read R1");
-r $R2 or err("Can't read R2");
$R1 ne $R2 or err("R1 and R2 are the same file");

my $f1 = IO::Uncompress::AnyUncompress->new($R1);
my $f2 = IO::Uncompress::AnyUncompress->new($R2);

my $counter=0;
while (defined $f1) {
  my $h1 = <$f1>;
  my $h2 = <$f2>;
  $counter++;
  $h1 eq $h2 or err("Mismatched ID for read $counter:\n$h1$h2");
  # skip over next 3 lines
  for (1..3) { scalar(<$f1>); scalar(<$f2>); }
  msg("Processed $counter reads...") if $counter % 100000 == 0;
}
msg("Checked $counter reads.");
