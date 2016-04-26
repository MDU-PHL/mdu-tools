#!/usr/bin/env perl
use strict;
use Data::Dumper;
use File::Path qw(make_path remove_tree);

my(@Options, $debug, $R1, $R2, $barlen, $outdir, $minfreq, $force, $cpus, $subsample, $keepfiles);
setOptions();

# Options
-r $R1 or err("Can't read --R1 $R1");
-r $R2 or err("Can't read --R2 $R2");
$barlen > 0 or err("Please provide length of barcode with --barlen");
$outdir or err("Please provide output folder with --outdir");

# Make output folder
if (-d $outdir) {
  if ($force) {
    msg("Forced removal of existing --outdir $outdir (please wait)");
    remove_tree($outdir);
  }
  else {
    err("Folder '$outdir' already exists. Try using --force");
  }
}
make_path($outdir);

# Overlap reads
msg("Overlapping reads with 'pear'");
run_cmd("pear -e -v 20 -q 10 -u 0 -j $cpus -f \Q$R1\E -r \Q$R2\E -o $outdir/reads");

# Count
msg("Counting barcodes");
my $head = $subsample > 0 ? " head -n $subsample | " : "";
run_cmd("cat \Q$outdir/reads.assembled.fastq\E | paste - - - - | $head cut -f 2 | cut -c1-$barlen | sort | uniq -c | sort -nr > \Q$outdir/barcodes.txt\E");

# Filter out low freq
my %keep;
my $found=0;
open COUNT, '<', "$outdir/barcodes.txt";
while (<COUNT>) {
  chomp;
  my($count, $barcode) = split ' ';  # special ' ' whitespacer
  $keep{$barcode}=$count if $count >= $minfreq;
#  msg("# $count $barcode");
  $found++;
}
my $kept = scalar keys %keep;
msg("Found $found barcodes, keeping $kept with frequency >= $minfreq");

# Go back and bin reads
msg("Binning reads into $kept files");
my %seq;
open RAW, "-|", "cat \Q$outdir/reads.assembled.fastq\E | paste - - - - | cut -f 2";
while (my $dna = <RAW>) {
  chomp $dna;
  my $barcode = substr $dna, 0, $barlen;
  next unless $keep{$barcode};
  push @{ $seq{$barcode} }, substr $dna, $barlen;
}

# Write out files
msg("Creating FASTA files");
my $counter=0;
for my $barcode (keys %keep) {
  print STDERR "\rWriting $barcode ", ++$counter, "/$kept";
  open my $fh, '>', "$outdir/$barcode.fna";
  my $seqs = $seq{$barcode};
  my $nseq = scalar(@$seqs);
  for my $i (1 .. $nseq) {
    print $fh ">$barcode.$i\n", $seqs->[$i-1], "\n";
  }
  close $fh;
}
print STDERR "\nOK\n";

# Alignment
msg("Aligning groups with clustal-omega");
$counter=0;
for my $barcode (keys %keep) {
  print STDERR "\rAligning $barcode ", ++$counter, "/$kept";
  run_cmd("clustalo -i \Q$outdir/$barcode.fna\E -o \Q$outdir/$barcode.aln\E --outfmt=fa --threads=$cpus", 1);
  run_cmd("cons -sequence \Q$outdir/$barcode.aln\E -outseq \Q$outdir/$barcode.cns\E -name $barcode 2> /dev/null", 1);
#  unlink "$outdir/$barcode.fna", "$outdir/$barcode.aln"
}
print STDERR "\nOK\n";

# Combining
msg("Combining consensus sequences");
run_cmd("cat \Q$outdir\E/*.cns > \Q$outdir/amplicons.fsa\E");

# FInal alignment
msg("Final alignment");
run_cmd("clustalo --auto -i \Q$outdir/amplicons.fsa\E -o \Q$outdir/amplicons.clw\E --outfmt=clustal --threads=$cpus");

# Cleanup
unless ($keepfiles) {
  msg("Deleting old files");
  unlink "$outdir/$_.cns", "$outdir/$_.fna", "$outdir/$_.aln" for keys %keep;
  unlink <$outdir/reads.*>;
}

msg("Results in $outdir/amplicons.*");
run_cmd("find $outdir -type f");
exit(0);

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
    {OPT=>"R1=s",  VAR=>\$R1, DEFAULT=>'', DESC=>"Read 1 FASTQ"},
    {OPT=>"R2=s",  VAR=>\$R2, DEFAULT=>'', DESC=>"Read 2 FASTQ"},
    {OPT=>"outdir=s",  VAR=>\$outdir, DEFAULT=>'', DESC=>"Output folder"},
    {OPT=>"force!",  VAR=>\$force, DEFAULT=>0, DESC=>"Force overwite of existing"},
    {OPT=>"barlen=i",  VAR=>\$barlen, DEFAULT=>0, DESC=>"Length of barcode"},
    {OPT=>"minfreq=i",  VAR=>\$minfreq, DEFAULT=>2, DESC=>"Minimum barcode frequency to keep"},
    {OPT=>"cpus=i",  VAR=>\$cpus, DEFAULT=>&num_cpus(), DESC=>"Number of CPUs to use"},
    {OPT=>"subsample=i",  VAR=>\$subsample, DEFAULT=>0, DESC=>"Only examine this many reads"},
    {OPT=>"keepfiles!",  VAR=>\$keepfiles, DEFAULT=>0, DESC=>"Do not delete intermediate files"},
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
  print "Usage: $0 [options] --R1 R1.fq.gz --R2 R2.fq.gz --outdir DIR --barlen NN\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------
