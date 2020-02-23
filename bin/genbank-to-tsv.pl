#!/usr/bin/env perl
use strict;
use Data::Dumper;
use Bio::SeqIO;

my(@Options, $debug, $format, $key, $use_tags, $noheader, 
             $empty, $boolean, $sep, $revsuffix, $ftype);
setOptions();

my @header = ($key, split m/,/, $use_tags);
my %use_tag = ( map { ($_=>1) } @header );
my %feat;
my $count=0;

my $in = Bio::SeqIO->new(-fh=>\*ARGV, -format=>$format);
while (my $seq = $in->next_seq) {
  print STDERR "Parsing: ",$seq->display_id,"\n";
  my $counter=0;
  for my $f ($seq->get_SeqFeatures) {
    $count++;
#    print STDERR "\rProcessing: ", $seq->display_id, " | $counter";
    next unless $f->has_tag($key);
    next unless $f->primary_tag =~ /$ftype/;
    my $nv = {
      chr => $seq->id,
      start => $f->start,
      end => $f->end,
      strand => $f->strand >= 0 ? '+' : '-',
      length => $f->length,
      ftype => $f->primary_tag,
    };
    for my $tag ($f->get_all_tags) {
      next unless $use_tag{$tag};
      my $value = ($f->get_tag_values($tag))[0];
      $value = $boolean if !defined($value) or $value eq '_no_value';
#      $value =~ s/$sep/_/g;  # ensure separator character not in a column value
      $nv->{$tag} = $value;
    }  
    $feat{ $nv->{$key} } = $nv;
  }
}
print STDERR Dumper(\%feat) if $debug;

print join($sep, @header),"\n" unless $noheader;
for my $id (sort keys %feat) {  # sort is important for Unix "join" command
  print join($sep, map { defined($feat{$id}{$_}) ? $feat{$id}{$_} : $empty } @header),"\n";
}

my $wrote = scalar keys %feat;
print STDERR "Processed $count features\n";
print STDERR "Wrote out $wrote features that had a /$key (set via --key)\n";
print STDERR "Done.\n";

#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"debug!",  VAR=>\$debug, DEFAULT=>0, DESC=>"Debug info"},
    {OPT=>"format=s",  VAR=>\$format, DEFAULT=>'genbank', DESC=>"Input format"},
    {OPT=>"ftype=s",  VAR=>\$ftype, DEFAULT=>'CDS|RNA', DESC=>"Which feature types"},
    {OPT=>"key=s",  VAR=>\$key, DEFAULT=>'locus_tag', DESC=>"What tag to use primary column"},
    {OPT=>"cols=s",  VAR=>\$use_tags, DEFAULT=>'chr,start,end,strand,length,ftype,gene,EC_number,product', DESC=>"Output these columns"},
    {OPT=>"noheader!",  VAR=>\$noheader, DEFAULT=>'', DESC=>"Don't print column headings as first line"},
    {OPT=>"empty=s",  VAR=>\$empty, DEFAULT=>'', DESC=>"What to use for empty values"},
    {OPT=>"boolean=s",  VAR=>\$boolean, DEFAULT=>'yes', DESC=>"What to use for boolean tags when true (eg. /pseudo)"},
    {OPT=>"sep=s",  VAR=>\$sep, DEFAULT=>"\t", DESC=>"Output separator, set to ',' for CSV"},
    {OPT=>"sep=s",  VAR=>\$sep, DEFAULT=>"\t", DESC=>"Output separator, set to ',' for CSV"},
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
  print "Usage: $0 [options] file.gbk file2.gbk ... > features.tab\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------

