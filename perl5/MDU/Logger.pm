package MDU::Logger;

use base Exporter;
@EXPORT_OK = qw(msg err);

our $quiet = 0;

#----------------------------------------------------------------------

sub quiet {
  my($self, $value) = @_;
  $quiet = $value if defined $value;
  return $quiet;
}

#----------------------------------------------------------------------

sub msg {
  return if $quiet;
#  my($pkg,undef,$line) = caller(1);
#  print STDERR "[$pkg:$line] @_\n";
  my $t = localtime;
  print STDERR "[$t] @_\n";
}
      
#----------------------------------------------------------------------

sub err {
  msg(@_);
  exit(1);
}

#----------------------------------------------------------------------

1;

