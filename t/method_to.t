#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

use Forward::Routes;



#############################################################################
### to method

my $r = Forward::Routes->new;

# set
my $route = $r->add_route('articles')->to('hello#world');
is_deeply $route->{defaults}, {controller => 'hello', action => 'world'};

# no getter
is $route->to, undef;

# overwrite
$route->to('country#city');
is_deeply $route->{defaults}, {controller => 'country', action => 'city'};



#############################################################################
# return value

$r = Forward::Routes->new;
$route = $r->add_route('articles');
my $rv = $route->to('hello#world');
is $route, $rv;


#############################################################################
### to method - partial

$r = Forward::Routes->new;
$route = $r->add_route('articles')->to('#world');
is_deeply $route->{defaults}, {controller => undef, action => 'world'};

$r = Forward::Routes->new;
$route = $r->add_route('articles')->to('hello#');
is_deeply $route->{defaults}, {controller => 'hello', action => undef};
