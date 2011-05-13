#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 8;


#############################################################################
### bridges

my $r = Forward::Routes->new;
my $bridge = $r->bridge('admin')->to('check#authentication');

$bridge->add_route('foo')->to('no#placeholders');
$bridge->add_route(':foo/:bar')->to('two#placeholders');

my $m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'admin/foo');
is_deeply $m->[0]->params, {controller => 'check', action => 'authentication'};
is $m->[0]->is_bridge, 1;
is_deeply $m->[1]->params, {controller => 'no', action => 'placeholders'};
is $m->[1]->is_bridge, undef;


$m = $r->match(get => '/hello/there');
is $m, undef;


$m = $r->match(get => '/admin/hello/there');
is_deeply $m->[0]->params, {controller => 'check', action => 'authentication'};
is_deeply $m->[1]->params, {controller => 'two', action => 'placeholders',
  foo => 'hello', bar => 'there'};
