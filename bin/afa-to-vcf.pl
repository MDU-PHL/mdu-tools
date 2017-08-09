#!/usr/bin/env perl
use strict;
use Bio::SeqIO;
use Data::Dumper;
use List::Util qw(max min);

my(@Options, $debug);
setOptions();

my $REF=0;

my @aln;
my $in = Bio::SeqIO->new(-fh=>\*ARGV, -format=>'fasta');
while (my $seq = $in->next_seq) {
  push @aln, [ $seq->id, split m//, uc($seq->seq) ];
  die unless @{$aln[0]} == @{$aln[-1]}; # ensure all same width
}
my $W = @{$aln[0]} - 1;
my $N = scalar(@aln);
print STDERR "Loaded AFA with $N seq x $W bp \n";
# look for longest ID not the ref (0)
my $idlen = max( map { length($aln[$_][0]) } (1 .. $N-1) );
print STDERR "Longest ID is $idlen chars\n";
#print Dumper(\@aln);

print "##fileformat=VCFv4.0\n";
print "##reference=$aln[$REF][0]\n";
print qq{##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">\n};
print qq{##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">\n};
print join("\t", qw(#CHROM POS ID REF ALT QUAL FILTER INFO FORMAT), map { $aln[$_][0] } (1..$N) ),"\n";

# assume 0 is the ref
for my $i (1 .. $W) {
  my $ref = $aln[$REF][$i];
  my @alt = map { $aln[$_][$i] } (1 .. $N-1);
  my @gt = map { ($_ eq $ref ? 0 : 1) } @alt;
  my @row = ( $aln[$REF][0], $i, '.', $ref, join(',',@alt), '.', 'PASS', "NS=$N", "GT", @gt );
  print join("\t", @row), "\n";
}

print STDERR "THIS CODE IS NOT COMPLETE!!!!\n"

#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"debug!",  VAR=>\$debug, DEFAULT=>0, DESC=>"Debug info"},
  );

  (!@ARGV) && (usage());

  &GetOptions(map {$_->{OPT}, $_->{VAR}} @Options) || usage();

  # Now setup default values.
  foreach (@Options) {
    if (defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
      ${$_->{VAR}} = $_->{DEFAULT};
    }
  }
}

sub usage {
  print "Usage: $0 [options] < alignment.afa > snps.vcf\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------
