#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 5;


#############################################################################
### match: captures method

my $r = Forward::Routes->new;
$r->add_route('articles/:id')->defaults(first_name => 'foo', last_name => 'bar')->name('one');
my $m = $r->match(get => 'articles/2');

# get hash
is_deeply $m->[0]->captures => {id => 2};

# get hash value
is $m->[0]->captures('id'), 2;



# no caputures
$r = Forward::Routes->new;
$r->add_route('articles')->defaults(first_name => 'foo', last_name => 'bar')->name('one');
$m = $r->match(get => 'articles');

# get hash
is_deeply $m->[0]->captures => {};

# get hash value
is $m->[0]->captures('id'), undef;



# nested routes
$r = Forward::Routes->new;
my $nested = $r->add_route('foo/:id');
$nested->add_route('bar/:id2');
$m = $r->match(get => 'foo/1/bar/4');

# get hash
is_deeply $m->[0]->captures => {id => 1, id2 => 4};

