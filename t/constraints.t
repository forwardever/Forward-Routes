#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 5;


#############################################################################
### constraints

my $r = Forward::Routes->new;

$r->add_route('articles/:id')->constraints(id => qr/\d+/)->name('article');

my $m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(get => 'articles/123');
is_deeply $m->[0]->params => {id => 123};



### path building
my $e = eval {$r->build_path('article')->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('article', id => 'abc')->{path}; };
like $@ => qr/Param 'id' fails a constraint/;
undef $e;

is $r->build_path('article', id => 123)->{path} => 'articles/123';
