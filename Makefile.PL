use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Video/Subtitle/SBV.pm';
my $repo = 'https://github.com/benkasminbullock/Video-Subtitle-SBV';

WriteMakefile (
    NAME => 'Video::Subtitle::SBV',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    PREREQ_PM => {
        'autodie' => 0,
        'Test::More' => 0,
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
);
