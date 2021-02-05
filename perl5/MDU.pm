package MDU;

use base Exporter;
#@EXPORT_OK = qw(msg err);

use MDU::Logger qw(msg err);

#----------------------------------------------------------------------

our $MDUDIR = '/home/seq/MDU/READS';

#----------------------------------------------------------------------

sub dir {
  my($self, $id) = @_;
  return $id ? "$MDUDIR/$id" : $MDUDIR;
}

#----------------------------------------------------------------------

sub all_ids {
  my $root = MDU->dir;
  opendir(my $dh, $root) or err("Could not read MDU dir: $root");
  my @id = grep { !m/^\./ and -d "$root/$_" } readdir($dh);
  closedir($dh);
  return @id;
}

#----------------------------------------------------------------------

sub id {
  my($self, $string) = @_;
#  $string =~ m/([12]\d{3}-\d{5}([_-]\S+)?|\d+)\b/;
#  msg("id($string) = $1");
  return $string;
#  return $1;
}

#----------------------------------------------------------------------

sub reads {
  my($self, $name) = @_;
  my $id = MDU->id($name);
  my $glob = MDU->dir . "/$id/*.f*q.gz";
  my @file = glob($glob);
  @file = sort @file; # ensure R1 before R2
  return @file;
}

#----------------------------------------------------------------------

1;
