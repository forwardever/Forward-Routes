#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 6;


#############################################################################
### method tests

my $m = Forward::Routes::Match->new;

is $m->name, undef;

is $m->_add_name('hello'), $m;
is $m->name, 'hello';

is $m->_add_name('you'), $m;
is $m->name, 'you';


#############################################################################
### nested

my $r = Forward::Routes->new;
my $nested = $r->add_route('articles')->name('one');
$nested->add_route('comments')->name('two');

$m = $r->match(get => 'articles/comments');
is $m->[0]->name, 'two';
