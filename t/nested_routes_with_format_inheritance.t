#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 12;



#############################################################################
### nested routes with format inheritance

my $root = Forward::Routes->new->format('html');
my $nested = $root->add_route('foo')->format('xml');
$nested->add_route('bar')->name('one');
$root->add_route('baz')->name('two');
$root->add_route('buz')->name('three')->format('jpeg');


my $m = $root->match(get => 'foo/bar');
is $m, undef;

$m = $root->match(get => 'foo/bar.html');
is $m, undef;

$m = $root->match(get => 'foo/bar.xml');
is_deeply $m->[0]->params => {format => 'xml'};


$m = $root->match(get => '/baz');
is $m, undef;

$m = $root->match(get => '/baz.xml');
is $m, undef;

$m = $root->match(get => '/baz.html');
is_deeply $m->[0]->params => {format => 'html'};


$m = $root->match(get => '/buz');
is $m, undef;

$m = $root->match(get => '/buz.html');
is $m, undef;

$m = $root->match(get => '/buz.jpeg');
is_deeply $m->[0]->params => {format => 'jpeg'};


# build path
is $root->build_path('one')->{path}, 'foo/bar.xml';
is $root->build_path('two')->{path}, 'baz.html';
is $root->build_path('three')->{path}, 'buz.jpeg';
