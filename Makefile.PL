#!/usr/bin/env perl

# Copyright (C) 2011, ForwardEver

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Forward::Routes',
    VERSION_FROM => 'lib/Forward//Routes.pm',
    ABSTRACT     => 'Forward::Routes: routes for web framework builders',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/forwardever/Forward-Routes'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
    PREREQ_PM => {'Carp' => 0},
    test      => {TESTS => 't/*.t'}
);

1;

