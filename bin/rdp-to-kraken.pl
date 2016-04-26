#!/usr/bin/perl -w
use strict;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::RealBin/../perl5";
use MDU qw(msg err);

my(@Options, $debug, $rdp_file, $names_file, $out_file);
setOptions();

my $in = Bio::SeqIO->new(-file=>"<$rdp_file", -format=>'fasta');
my $out = Bio::SeqIO->new(-file=>">$out_file", -format=>'fasta');

# 1305867 |       Cellulomonas persica JCM 18111  |               |       scientific name |
msg("Loading taxonomy: $names_file");
my %id_of;
open TAX, '<', $names_file;
while (<TAX>) {
  next if m/type material|authority/;
  next unless m{ ^ (\d+) \s* \| \s* ([^|]+) \s }x;
  $id_of{$2} = $1;
  msg("$1 = [$2]") if $debug;
}
close TAX;
msg("Taxa stored:", scalar(keys %id_of));

my $rdp=0;
my $rdp_ok=0;

msg("Filtering $rdp_file ...");
while (my $seq = $in->next_seq) {
#  print STDERR "\rParsing: ",$seq->id, " ", $seq->desc;
  $rdp++;
  my $name = $seq->desc;
  $name =~ s/;.*$//g;
  my $taxid = $id_of{$name} or next;
  $rdp_ok++;
  msg("$taxid\t$name") if $debug;
  $seq->id($seq->id."|kraken:taxid|$taxid");
  $out->write_seq($seq);
  msg("Wrote $rdp_ok/$rdp to $out_file so far...") if $rdp % 100_000 == 0;
}
printf STDERR "\nRead $rdp, wrote $rdp_ok (%.2f%%)\n", 100*$rdp_ok/$rdp;

#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"debug!",  VAR=>\$debug,      DEFAULT=>0, DESC=>"Debug info"},
    {OPT=>"rdp=s",   VAR=>\$rdp_file,   DEFAULT=>'/bio/data/rdp/latest/RDP', DESC=>"Input FASTA file from RDP"},
    {OPT=>"names=s", VAR=>\$names_file, DEFAULT=>'/bio/data/taxonomy/ncbi/latest/names.dmp', DESC=>"NCBI taxonomy names file"},
    {OPT=>"out=s",   VAR=>\$out_file,   DEFAULT=>'', DESC=>"Output FASTA file"},
  );

  #(!@ARGV) && (usage());

  &GetOptions(map {$_->{OPT}, $_->{VAR}} @Options) || usage();

  # Now setup default values.
  foreach (@Options) {
    if (defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
      ${$_->{VAR}} = $_->{DEFAULT};
    }
  }
}

sub usage {
  print "Usage: $0 [options] < file.gbk > file.fna\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------
