package MDU;

use base Exporter;
@EXPORT_OK = qw(msg err);

#----------------------------------------------------------------------

my $MDUDIR = '/mnt/seq/MDU/READS';
our $quiet = 0;

#----------------------------------------------------------------------

sub dir {
  my($self, $id) = @_;
  return $id ? "$MDUDIR/$id" : $MDUDIR;
}

#----------------------------------------------------------------------

sub all_ids {
  my $root = MDU->dir;
  opendir(my $dh, MDU->dir) or err("Could not read MDU dir: $root");
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
  my @file = glob( MDU->dir . "/$id/*.f*q.gz" );
  @file = sort @file; # ensure R1 before R2
  return @file if @file==2;
  return;
}

#----------------------------------------------------------------------

sub quiet {
  my($self, $value) = @_;
  $quiet = $value if defined $value;
  return $quiet;
}

#----------------------------------------------------------------------

sub msg {
#  my $self = shift;
  return if $quiet;
  print STDERR "@_\n";
}
      
#----------------------------------------------------------------------

sub err {
#  my $self = shift;
  msg('ERROR:', @_);
  exit(1);
}

#----------------------------------------------------------------------

1;
