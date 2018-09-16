#!/usr/bin/env perl

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
use strict;
use File::Fetch;
use Getopt::Std;
use File::Basename;
use Data::Dumper;

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
our $VERSION = "0.1.0";
my $EXE = basename($0);
my $URL = 'http://phaster.ca/phaster_api';

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
sub msg { print STDERR "@_\n"; }
sub wrn { msg("WARNING:", @_); }
sub err { msg("ERROR:", @_); exit(1); }

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
sub HELP_MESSAGE {
  msg("Usage: $EXE [-d] -a ACCESSION [-v VERSION] > phage.bed");
  exit(0);
}
sub VERSION_MESSAGE {
  msg("$EXE $VERSION");
  exit(0);
}

my %opt;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
getopts('Vda:v:', \%opt);
$opt{V} and VERSION_MESSAGE();
$opt{a} or HELP_MESSAGE();

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
my $acc = $opt{a} . '.' . ($opt{v} || '1');
my $url = "$URL?acc=$acc";
msg("Fetching:", $url); #exit(-1);
my $ff = File::Fetch->new(uri=>$url) or err("bad URI? $url");
my $json = '';
my $where = $ff->fetch(to=>\$json) or err( $ff->error );
print STDERR Dumper($json) if $opt{d}; # debug
$json =~ m/:null|"error"/ and err(Dumper($json));
my $count = 0;
while ($json =~ m/\b(\d+)-(\d+)\b/g) {
  print join("\t", $acc, $1 - 1, $2),"\n";
  $count++;
}
msg("Found $count phage regions in $acc");

__DATA__

# http://phaster.ca/instructions

3. GET phaster.ca/phaster_api?acc=<;> - Input Accession number, GI number, or Job ID.
PHASTER is run for the given Accession or GI number (or an existing result retrieved). The status and/or the results are returned. If a Job ID for a submission is given, the status for that submission is returned. The results are returned if the job is complete.

Response:
A JSON object with the following fields:
- 'job_id' - The Accession number, GI number, or Job ID of the submission.
- 'status' - The status of the submission. This may include the position of the job in the queue if the job has not started to run yet.
- 'url' - This field is included if the submission completed successfully. The given url may be used to view the results using the web interface.
- 'zip' - This field is included if the submission completed successfully. The given url may be used to download the available result files.
- 'summary' - This field is included if the submission completed successfully. The summary of the results is retrieved.
- 'error' - This field is included if there are initial input problems, or if the submission failed.

Example: 'wget "http://phaster.ca/phaster_api?acc=NC_000913" -O Output_filename'
Response: {"job_id":"NC_000913.3","status":"Complete","url":"phaster.ca/submissions/NC_000913.3",
"zip":"phaster.ca/submissions/NC_000913.3.zip","summary":"Criteria for scoring prophage regions..."}"

Example: 'wget "http://phaster.ca/phaster_api?acc=ZZ_023a167bf8" -O Output_filename'
Response: {"job_id":"ZZ_023a167bf8","status":"Running..."}

