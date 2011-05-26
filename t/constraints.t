#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 2;


#############################################################################
### constraints

my $r = Forward::Routes->new;

$r->add_route('articles/:id')->constraints(id => qr/\d+/);

my $m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(get => 'articles/123');
is_deeply $m->[0]->params => {id => 123};
