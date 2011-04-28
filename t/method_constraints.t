#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 30;


#############################################################################
### no method constraint

my $r = Forward::Routes->new;
my $nested = $r->add_route('foo')->defaults(test => 1);

my $m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(put => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(delete => 'foo');
is_deeply $m->[0]->params => {test => 1};


#############################################################################
### multiple method constraints

$r = Forward::Routes->new;
$nested = $r->add_route('foo')->via('post','put')->defaults(test => 1);

$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(put => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(delete => 'foo');
is $m, undef;


#############################################################################
### method constraints and nested routes

$r = Forward::Routes->new;
$nested = $r->add_route('foo');
$nested->add_route->via('get')->defaults(test => 1)->to('foo#get');
$nested->add_route->via('post')->to('foo#post')->defaults( test => 2);
$nested->add_route->via('put')->to('foo#put');

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'post', test => 2};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'get', test => 1};

$m = $r->match(delete => 'foo');
is $m, undef;


#############################################################################
### upper case vs. lower case

$r = Forward::Routes->new;
$r->add_route('logout')->via('GET');
ok $r->match(get => 'logout');
ok $r->match(GET => 'logout');
ok !$r->match(post => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('get');
ok $r->match(GET => 'logout');
ok !$r->match(POST => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('get','post');
ok $r->match(GET => 'logout');
ok $r->match(POST => 'logout');
ok !$r->match(PUT => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('GET','POST');
ok $r->match(get => 'logout');
ok $r->match(GET => 'logout');
ok $r->match(post => 'logout');
ok $r->match(POST => 'logout');
ok !$r->match(put => 'logout');
ok !$r->match(PUT => 'logout');


#############################################################################
### pass array ref

$r = Forward::Routes->new;
$r->add_route('photos/:id')->via([qw/get post PUT/]);
ok $r->match(get => 'photos/1');
ok $r->match(POST => 'photos/1');
ok !$r->match(head => 'photos/1');
ok $r->match(put => 'photos/1');
ok $r->match(PUT => 'photos/1');
