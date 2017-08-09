#!/usr/bin/env perl
use strict;
use Data::Dumper;
use Regexp::Common qw(URI);
use File::Spec;

my $ascp = qx(which ascp) or die "could not fine 'ascp' please install Aspera";
chomp $ascp;

$ascp .= " -v -i $ascp/../etc/asperaweb_id_dsa.openssh -v -T -k 1 --mode recv";
print STDERR "# COMMAND: $ascp\n";

for my $url (@ARGV) {
  download($url);
}

sub download {
  my($url) = @_;
  print STDERR "# IN = $url\n";
  my $cmd = "wget '$url'";
  if ($url =~ m/$RE{URI}{FTP}{-keep}/) {
    my($host,$file) = ($5, $9);
    my $user = $host =~ m/ncbi/ ? 'anonftp' : 'fasp';
    $cmd = "$ascp --host $host --user $user /$file .\n";
  }
  print "$cmd\n";
}
