#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 3;


#############################################################################
### method constraints and nested routes

my $r = Forward::Routes->new;
my $nested = $r->add_route('foo');
$nested->add_route->via('get')->defaults(test => 1)->to('foo#get');
$nested->add_route->via('post')->to('foo#post')->defaults( test => 2);
$nested->add_route->via('put')->to('foo#put');

my $m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'post', test => 2};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'get', test => 1};

$m = $r->match(delete => 'foo');
ok not defined $m;
