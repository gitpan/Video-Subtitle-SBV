use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Video::Subtitle::SBV',
    VERSION_FROM => 'lib/Video/Subtitle/SBV.pm',
    PREREQ_PM => {
        'autodie' => 0,
        'Test::More' => 0,
    },
);
