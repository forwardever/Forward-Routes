#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use Forward::Routes;



#############################################################################
### nested routes with namespace inheritance

my $root = Forward::Routes->new->namespace('Root');
my $nested1 = $root->add_route('foo')->namespace('Hello::Foo');
$nested1->add_route('bar')->to('Controller#action');
$root->add_route('baz')->name('two');
$root->add_route('buz')->name('three')->namespace('Buz');
$root->add_route('undef_namespace')->namespace(undef);

my $m = $root->match(get => '/foo');
is $m, undef;

$m = $root->match(get => 'foo/bar');
is $m->[0]->namespace, 'Hello::Foo';

# Match->controller_class and Match->action
is $m->[0]->controller_class, 'Hello::Foo::Controller';
is $m->[0]->action, 'action';

$m = $root->match(post => '/baz');
is $m->[0]->namespace, 'Root';

$m = $root->match(get => '/buz');
is $m->[0]->namespace, 'Buz';

$m = $root->match(get => '/undef_namespace');
is $m->[0]->namespace, undef;


