use warnings;
use strict;
use autodie;
use Test::More tests => 1;
use FindBin;
BEGIN { use_ok('Video::Subtitle::SBV') };
use Video::Subtitle::SBV;

my $subtitles = Video::Subtitle::SBV->new ();
$subtitles->set_verbosity ('yes');
my $input = "$FindBin::Bin/6-2.txt";
$subtitles->parse_file ($input);
my $output = "$FindBin::Bin/6-2-out.txt";
$subtitles->write_file ($output);
#unlink $output;

# Local variables:
# mode: perl
# End:
