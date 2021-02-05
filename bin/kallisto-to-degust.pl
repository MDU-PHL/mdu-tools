#!/usr/bin/env perl
use strict;
use Data::Dumper;
use File::Basename;

my(@Options, $debug, $lkey, $rfile, $rkey, $rcount, $empty, $sep);
setOptions();

my($counts,$header) = tsv_to_hash(shift @ARGV, $lkey);
#print Dumper($counts);
#print Dumper($header);

for my $kdir (@ARGV) {
  print STDERR "Kallisto: $kdir/$rfile\n";
  my($k) = tsv_to_hash("$kdir/$rfile", $rkey);
#  print Dumper($k);
  my $name = basename($kdir);
  for my $id (keys %$counts) {
    $counts->{$id}{$name} = $k->{$id}{$rcount} || $empty;
  }
  push @$header, $name;
}
#print Dumper($counts, $header);

sub tsv { join($sep,@_)."\n"; }

print tsv(@$header);
for my $gene (sort keys %$counts) {
  print tsv( map { $counts->{$gene}{$_} } @$header);
}



sub tsv_to_hash {
  my($fname, $key) = @_;
  my $result;
  my @hdr;
  open my $TSV, '<', $fname or die "Can't open file: $fname";
  while (<$TSV>) {
    chomp;
    my @col = split m/\t/;
    #print STDERR Dumper(\@hdr, \@col);
    if (@hdr) {
      die "header/row mismatch" unless @col == @hdr;
      my $hash = { map { ($hdr[$_] => $col[$_]) } (0 .. $#hdr) };
      die "no key '$key' in $fname row:\n".Dumper($hash) unless exists $hash->{$key};
      $result->{ $hash->{$key} } = $hash;
    }
    else {
      @hdr = @col;
      #print STDERR Dumper(\@hdr);
    }
  }
  return ($result, [ @hdr ]);
}

sub tsv_to_array {
  my($fname) = @_;
  my $result;
  open my $TSV, '<', $fname;
  while (<$TSV>) {
    chomp;
    push @{$result}, [ split m/\t/ ];
  }
  return $result;
}



#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"debug!",  VAR=>\$debug, DEFAULT=>0, DESC=>"Debug info"},
    {OPT=>"lkey=s",  VAR=>\$lkey, DEFAULT=>'locus_tag', DESC=>"Column to base join on"},
    {OPT=>"rfile=s",  VAR=>\$rfile, DEFAULT=>'abundance.tsv', DESC=>"What Kallisto file to use"},
    {OPT=>"rkey=s",  VAR=>\$rkey, DEFAULT=>'target_id', DESC=>"What tag to use primary column"},
    {OPT=>"rcount=s",  VAR=>\$rcount, DEFAULT=>'est_counts', DESC=>"What tag to use primary column"},
    {OPT=>"empty=s",  VAR=>\$empty, DEFAULT=>'0', DESC=>"What to use for empty values"},
    {OPT=>"sep=s",  VAR=>\$sep, DEFAULT=>"\t", DESC=>"Output separator, set to ',' for CSV"},
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
  print "Usage: $0 [options] genbank.tsv <kallisto_dir1> <kallisto_dir2> ...\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------

