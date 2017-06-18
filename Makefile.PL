use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'JIP::Debug',
    AUTHOR           => q{Vladimir Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/JIP/Debug.pm',
    ABSTRACT_FROM    => 'lib/JIP/Debug.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'English'         => 0,
        'Test::More'      => 0,
        'Capture::Tiny'   => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'Exporter'     => 0,
        'English'      => 0,
        'Fcntl'        => 0,
        'Data::Dumper' => 0,
        'Carp'         => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES => 'JIP-Debug-*'},
);

