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

msg("Checking $R1 vs. $R2 slowly...");
my $f1 = IO::Uncompress::AnyUncompress->new($R1);
my $f2 = IO::Uncompress::AnyUncompress->new($R2);

my $counter=0;
#while (!$f1->eof and !$f2->eof) {
while (1) {
#  my $h1 = <$f1> or last; 
  my $h1 = $f1->getline or last; 
  chomp $h1;
#  my $h2 = <$f2> or last; 
  my $h2 = $f2->getline or last;
  chomp $h2;
  $counter++;
  #msg("$counter | $h1 | $h2");
  if ($h1 =~ m{/1$} and $h2 =~ m{/2$}) {
    $h1 =~ s/..$//;
    $h2 =~ s/..$//; 
  }
  elsif ($h1 =~ m/ /) {
    $h1 =~ s/ .*$//;
    $h2 =~ s/ .*$//;
  }
  $h1 eq $h2 or err("Mismatched ID for read $counter:\nR1=$h1\nR2=$h2");
  # skip over next 3 lines
  #for (1..3) { scalar(<$f1>); scalar(<$f2>); }
  for (1..3) { $f1->getline; $f2->getline; }
  msg("Processed $counter reads...") if $counter % 100000 == 0;
}
msg("Checked $counter reads.");
$f1->eof or err("$R1 has extra reads in it");
$f2->eof or err("$R2 has extra reads in it");

