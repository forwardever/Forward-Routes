#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use Forward::Routes;



#############################################################################
### save root route as class var

my $r = Forward::Routes->new->add_route('test1')->to('Foo#bar');
isa_ok $Forward::Routes::routes, 'Forward::Routes';
ok $Forward::Routes::routes->match(get => 'test1');


$r = Forward::Routes->new->add_resources('test');
isa_ok $Forward::Routes::routes, 'Forward::Routes';
my $m = $Forward::Routes::routes->match(get => 'test/123');
is_deeply $m->[0]->params, {controller => 'Test', action => 'show', id => 123};
