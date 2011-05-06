#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 2;


#############################################################################
### match: params method

my $r = Forward::Routes->new;
$r->add_route('articles/:id')->defaults(first_name => 'foo', last_name => 'bar')->name('one');

my $m = $r->match(get => 'articles/2');

# get hash
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar', id => 2};

# get hash value
is $m->[0]->params('first_name'), 'foo';

