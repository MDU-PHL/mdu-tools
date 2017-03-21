#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;
use List::Util qw(min max sum);
use List::MoreUtils qw(uniq all any);
use Text::CSV;

my $PARALOG_SEP = ',';
my $TAXA_COL = 14;
my $MISSING = '*';

my(@Options, $verbose, $roary, $prefix);
setOptions();
$prefix or err("Please provide a --prefix for the fripan output files");

open my $ROARY, '<', $roary or err("Could not open --roary file: $roary");
msg("Opened: $roary");

my %fh;
for my $ext ('proteinortho', 'strains', 'descriptions') {
  my $fname = "$prefix.$ext";
  open $fh{$ext}, '>', $fname or err("Could not open '$fname' for writing.");
  msg("Will save to: $fname");
}

# read gene_presence_absence.csv from stdin
#  0  "Gene"
#  1  "Non-unique Gene name"
#  2  "Annotation"
#  3  "No. isolates"
#  4  "No. sequences"
#  5  "Avg sequences per isolate"
#  6  "Genome Fragment"
#  7  "Order within Fragment"
#  8  "Accessory Fragment"
#  9  "Accessory Order with Fragment"
# 10  "QC"
# 11  "Min group size nuc"
# 12  "Max group size nuc"
# 13  "Avg group size nuc"

# XXX.proteinortho
#0  # Species
#1  Genes
#2  Alg.-Conn.
#3  BPH0693
#4  BPH0694
#5  BPH0695
#6  BPH0696
# line 2
#0  3
#1  3
#2  1
#3  BPH0693_00454
#4  *
#5  BPH0695_01451
#6  BPH0696_02515
                                   
my $csv = Text::CSV->new() or die $!;
my $count=0;
my $N=0;
my @id;
my $G=0;

while (my $row = $csv->getline($ROARY) ) {
  if ($count == 0) {
    @id = splice @$row, $TAXA_COL;
    $N = scalar(@id);
    msg("Found $N taxa: $id[0] ... $id[-1]");
    print {$fh{proteinortho}} tsv('# Species', 'Genes', 'Alg.-Conn.', @id);
    print {$fh{strains}} tsv('ID', 'Order');
    print {$fh{strains}} tsv($id[$_], $_+1) for (0 .. $#id);
  }
  else {
    my @cds = map { $_ ? $_ : $MISSING } @$row[$TAXA_COL .. $#$row];
    map { s/\t/,/g } @cds;
    print {$fh{proteinortho}} tsv( @$row[3,4,5], @cds );
    for my $lt (grep { $_ ne $MISSING } @cds) {
      my $desc = $row->[2] || 'unannotated protein';
      $desc .= ' ('.$row->[0].')' if $row->[0];
      print {$fh{descriptions}} tsv($lt, $desc);
      $G++;
    }
  }
  $count++;
}

$count--;
msg("Processed $count ortholog clusters and $G genes.");
msg("Done.");


#----------------------------------------------------------------------
sub tsv {
  if (any { m/\t/ } @_) { 
    err("Found <TAB> within a cell row: @_")
  }
  return join("\t", @_)."\n";
}

#----------------------------------------------------------------------

sub msg {
  print STDERR "@_\n";
}
  
#----------------------------------------------------------------------
  
sub err {
  print STDERR "ERROR: @_\n";
  exit(1);
}
      
#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"verbose!",  VAR=>\$verbose, DEFAULT=>0, DESC=>"Verbose output"},
    {OPT=>"roary=s",   VAR=>\$roary,  DEFAULT=>'gene_presence_absence.csv', DESC=>"Roary ortholog matrix file"},
    {OPT=>"prefix=s",  VAR=>\$prefix,  DEFAULT=>'', DESC=>"Prefix for Fripan output files"},
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
  print "Usage: $0 [options] gene_presence_absence.csv\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------

