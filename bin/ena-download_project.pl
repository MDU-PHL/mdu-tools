#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
use Fatal;
use File::Path qw(make_path);
use File::Spec;
use File::Which qw(which);
use File::Slurp;

#my @FIELD = qw(run_accession sample_accession sample_alias study_accession
#fields=study_accession,secondary_study_accession,sample_accession,secondary_sample_accession,
#  experiment_accession,run_accession,tax_id,scientific_name,instrument_model,
#  library_layout,fastq_ftp,fastq_galaxy,submitted_ftp,submitted_galaxy,cram_index_ftp,cram_index_galaxy,sample_alias
#
my($aspera) = which('ascp');
$aspera = qx(dirname `readlink -m '$aspera/..'`);
chomp $aspera;

my(@Options, $verbose,$sampleids, $nose, $nope);
setOptions();

@ARGV or die "Please supply a Project ID to download";
my $pid = shift @ARGV;

my $ascp = "$aspera/bin/ascp";
-x $ascp or die "Can't find 'ascp' command here: $ascp";
my $askey = "$aspera/etc/asperaweb_id_dsa.openssh";
-r $askey or die "Can't see Aspera SSH key here: $askey";

print STDERR "Fetching run table for $pid from ENA\n";
my $url = "http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=${pid}".
          "&result=read_run&download=txt&fields=run_accession,sample_alias,fastq_ftp,submitted_ftp";
print STDERR "URL: $url\n" if $verbose;
my $content = get($url);
$content or die "Could not download $pid run table\n";

my @row = split m/\n/, $content;
my $N = scalar(@row);
$N > 0 or die "No samples found in $pid\n";
print STDERR Dumper($content) if $verbose;
$N--; # remove header line
print STDERR "Found $N samples in $pid\n";

print STDERR "Making folder: $pid\n";
make_path($pid);

my $rt_fn = "$pid/$pid.tab";
print STDERR "Saving run table: $rt_fn\n";
write_file($rt_fn, $content);

print STDERR "Generating Makefile: $pid/Makefile\n";
open my $MF, '>', "$pid/Makefile";
print $MF "# $pid\n# $url\n";
# http://www.ebi.ac.uk/ena/browse/read-download#downloading_files_aspera
print $MF "ASCP=$ascp -QT -l 300m -i $askey\n";
print $MF "all: files\n";

my $err = 0;
my $fq = 0;
my $skip_se = 0;
my $skip_pe = 0;
my @dep;

# 0              1             2          3
# run_accession, sample_alias, fastq_ftp, submitted_ftp

for my $row (@row) {
  next if $row =~ m/^run_accession/;
  my @col = split m/\t/, $row;
  my $dir = $sampleids ? $col[1] : $col[0];
  my $label = join ' / ', $col[0], $col[1];
  unless ($col[2] or $col[3]) {
    print STDERR "WARNING: no ENA FASTQ for $label\n";
    next;
  }
  my @fastq = split m{;}, ($col[2] || $col[3]); # fallback to submitter FASTQ

  if ($nose and @fastq==1) {
    print STDERR "NOTICE: skipping single-end sample $label\n";
    $skip_se++;
    next;
  }
  if ($nope and @fastq==2) {
    print STDERR "NOTICE: skipping paired-end sample $label\n";
    $skip_pe++;
    next;
  }
  print STDERR "Adding sample: $label\n";
#  print "mkdir '$pid/$dir'\n";
  $err++;
  for my $fastq (@fastq) {
    my(undef,undef,$filename) = File::Spec->splitpath($fastq);
    my $asp = $fastq;
    $asp =~ s/^ftp/era-fasp\@fasp/; # convert FTP to ASP
    $asp =~ s/ac.uk/ac.uk:/;
    my $target = "$dir/$filename";
    print $MF "$target:\n";
    print $MF "\tmkdir -p $dir\n";
    print $MF "\t\$(ASCP) $asp $target\n";
    push @dep, $target;
    $fq++;
  }
}
print $MF "files: @dep\n";
print STDERR "Skipped $skip_pe paired-end read samples\n" if $nope;
print STDERR "Skipped $skip_se single-end read samples\n" if $nose;
print STDERR "Prepared $err runs with total of $fq FASTQ files for download.\n";
print STDERR "Type 'make -C $pid' to commence downloading!\n";

#./.aspera/connect/bin/ascp  -QT -l 300m
# -i ~/.aspera/connect/etc/asperaweb_id_dsa.openssh
# era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/ERR111/ERR111871/ERR111871_1.fastq.gz ./

#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"verbose!",  VAR=>\$verbose, DEFAULT=>0, DESC=>"Verbose output"},
    {OPT=>"aspera=s",  VAR=>\$aspera, DEFAULT=>$aspera, DESC=>"AsperaConnect installation dir"},
    {OPT=>"sampleids!",  VAR=>\$sampleids, DEFAULT=>0, DESC=>"Use Sample IDs for names not Run IDs"},
    {OPT=>"no-se!",  VAR=>\$nose, DEFAULT=>0, DESC=>"Exclude single-end read samples"},
    {OPT=>"no-pe!",  VAR=>\$nope, DEFAULT=>0, DESC=>"Exclude paired-end read samples"},
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
  print "Synopsis: Download and organize FASTQ files from an SRA Project\n";
  print "Usage: $0 [options] <PRJxxxx>\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------

__DATA__

http://www.ebi.ac.uk/ena/data/warehouse/filereport?
accession=PRJEB3223
result=read_run
fields=study_accession,secondary_study_accession,sample_accession,secondary_sample_accession,
  experiment_accession,run_accession,tax_id,scientific_name,instrument_model,
  library_layout,fastq_ftp,fastq_galaxy,submitted_ftp,submitted_galaxy,cram_index_ftp,cram_index_galaxy,sample_alias
download=txt

