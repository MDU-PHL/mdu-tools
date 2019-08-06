#!/usr/bin/env perl
use strict;
use File::Basename;
use List::Util qw(uniq);
 
sub msg { print "@_\n"; }
sub err { msg("ERROR:", @_); exit(-1); }
sub wrn { msg("WARNING:", @_); }

my $MISSING = '.';
my $EXE = basename($0);

@ARGV >= 2 or err("Usage: $EXE <file1.fa> <file2.fa>");
my $f1 = shift(@ARGV);
-r $f1 or err("Can't read file 1 '$f1'");
my $f2 = shift(@ARGV);
-r $f2 or err("Can't read file 2 '$f2'");

my($s1,$n1) = slurp_fasta($f1);
my($s2,$n2) = slurp_fasta($f2);

my @ids = uniq( keys %$s1, keys %$s2 );
msg("Identified", 0+@ids, "unique sequence IDs");
print tsv("#$f1", "#$f2");
for my $id (sort { $a cmp $b } @ids) {
  if (not exists $s1->{$id}) {
    print tsv($MISSING, $id);
  }
  elsif (not exists $s2->{$id}) {
    print tsv($id, $MISSING);
  }
}

my @seqs = uniq( keys %$n1, keys %$n2 );
msg("Identified", 0+@seqs, "unique sequences");
print tsv("#$f1", "#$f2");
for my $seq (@seqs) {
  my $q1 = $n1->{$seq};
  my $q2 = $n2->{$seq};
  if ($q1 and $q2 and $q1 ne $q2) {
    msg("Dupe seq, diff name : $q1 vs $q2");
  }
  
  if (not exists $n1->{$seq}) {
  #  print tsv($MISSING, $seq);
  }
  elsif (not exists $n2->{$seq}) {
  #  print tsv($seq, $MISSING);
  }
}
exit(0);


#-----------------------------------------------------------

sub tsv {
  return join("\t", @_)."\n";
}

sub slurp_fasta {
  my($fname) = @_;
  msg("Loading: $fname");
  my $s = {};
  my $n = {};
  open my $FASTA, '-|', "seqtk seq -A '$fname'";
  while (my $hdr = <$FASTA>) {
    $hdr =~ m/^>(\S+)/;
    my $id = $1;
    my $seq = <$FASTA>;
    chomp $seq;
    $seq = uc($seq);
    $s->{$id} = $seq;
    $n->{$seq} = $id;
  }
  close $FASTA;
  msg("$fname has", scalar(keys(%$s)), "unique sequence IDS");
  msg("$fname has", scalar(keys(%$n)), "unique sequences");
  return($s,$n);
}

