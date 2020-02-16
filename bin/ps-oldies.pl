#!/usr/bin/env perl
use strict;
use POSIX qw(strftime);

my $month = strftime("%b", localtime);

my $ps = "ps -eo user:32,start_time,pid,cmd --sort=user";
open my $PS, '-|', $ps;
while (<$PS>) {
  chomp;
  next if m/^USER/;
  my($user,$stime,$pid,$cmd) = split ' ', $_;
  $user =~ s/^STUDENT.//;
  next if $user eq 'root';
  next if $stime =~ m/^\d/;
  next if $stime =~ m/^$month/;
  print join("\t", $user, $pid, $stime, $cmd),"\n";
}
close $PS;
