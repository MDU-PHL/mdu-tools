#!/usr/bin/env perl
use strict;
use Data::Dumper;
use Fatal;

my(@Options, $debug, $dsk_fn, $taxa_fn);
setOptions();

# Options
-r $dsk_fn or err("Can't read --dsk $dsk_fn");
-r $taxa_fn or err("Can't read --taxa $taxa_fn");

# Taxa
my %taxa_index;
my @taxa;
msg("Opening taxa: $taxa_fn");
open TAXA, '<', $taxa_fn;
my $index=0;
while (my $t = <TAXA>) {
  chomp $t;
  push @taxa, $t;
  $taxa_index{$t} = $index++;
}
msg("Loaded $index taxa.");

# DSK
# GTGCCTTTTTCTTCATGTAATAATTGATTCC NC_017027.fna:1 NC_017764.fna:1
msg("Streaming: $dsk_fn");
open DSK, "-|", "gunzip -f -c -d \Q$dsk_fn\E";
my $row=0;
my @freq;
print join("\t", "KMER", @taxa),"\n";
while (my $line = <DSK>) {
  chomp $line;
  $line =~ s/:\d+\b//g; # remove counts, only care if present or not
  my($kmer, @hit) = split ' ', $line;  # space separated?
  my %hit = map { ($_ => 1) } @hit;
  my @row = map { $hit{$_} ? 1 : 0 } @taxa;
  print join("\t", $kmer, @row),"\n";
  $row++;
  msg("Peeking at row $row: $line") if $row % 123457 == 0;
  $freq[ scalar(keys %hit) ]++;
}
msg("Processed $row kmers");
msg("Taxa participation frequency per kmer:");
for my $i (1 .. $#freq) {
  my $count = $freq[$i] || 0;
  msg("$i\t$count");
}


#----------------------------------------------------------------------

sub run_cmd {
  my($cmd, $quiet) = @_;
  msg("Running: $cmd") unless $quiet;
  system($cmd)==0 or err("Error $? running command");
}

#----------------------------------------------------------------------
sub msg {
  print STDERR "@_\n";
}
      
#----------------------------------------------------------------------
sub err {
  msg(@_);
  exit(1);
}

#----------------------------------------------------------------------
sub num_cpus {
  my($num)= qx(getconf _NPROCESSORS_ONLN); # POSIX
  chomp $num;
  return $num || 1;
}
   
#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"debug!",  VAR=>\$debug, DEFAULT=>0, DESC=>"Debug info"},
    {OPT=>"dsk=s",  VAR=>\$dsk_fn, DEFAULT=>'dsm_input.txt.gz', DESC=>"DSK report"},
    {OPT=>"taxa=s",  VAR=>\$taxa_fn, DEFAULT=>'taxa.txt', DESC=>"List of taxa"},
  );

#  (!@ARGV) && (usage());

  &GetOptions(map {$_->{OPT}, $_->{VAR}} @Options) || usage();

  # Now setup default values.
  foreach (@Options) {
    if (defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
      ${$_->{VAR}} = $_->{DEFAULT};
    }
  }
}

sub usage {
  my $exe = $0;
  $exe =~ s{^.*/}{};
  print "Usage: $exe [options] --dsk dsm_input.txt.gz --taxa isolates.txt > matrix.tab\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------
