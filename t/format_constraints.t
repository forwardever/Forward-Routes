#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 30;


#############################################################################
### format

### no format constraint, but format passed
### one format constraint
my $r = Forward::Routes->new;
$r->add_route('foo');
$r->add_route(':foo/:bar');

my $m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there.html'};



### one format constraint
$r = Forward::Routes->new->format('html');
$r->add_route('foo');
$r->add_route(':foo/:bar');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

# match again (params empty again)
$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

# now paths without format
$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'hello/there');
is $m, undef;

# now paths with wrong format
$m = $r->match(get => 'foo.xml');
is $m, undef;

$m = $r->match(get => 'hello/there.xml');
is $m, undef;



### pass empty format explicitly
$r = Forward::Routes->new->format('');
$r->add_route('foo');
$r->add_route(':foo/:bar');

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};


# now paths with format
$m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is $m, undef;



### multiple format constraints
$r = Forward::Routes->new->format('html','xml');
$r->add_route('foo');
$r->add_route(':foo/:bar');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

$m = $r->match(get => 'foo.xml');
is_deeply $m->[0]->params => {format => 'xml'};

$m = $r->match(get => 'hello/there.xml');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'xml'};

# match again (params empty again)
$m = $r->match(get => 'foo.xml');
is_deeply $m->[0]->params => {format => 'xml'};

# now paths without format
$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'hello/there');
is $m, undef;

# now paths with wrong format
$m = $r->match(get => 'foo.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/there.jpeg');
is $m, undef;



### multiple format constraints, with empty format allowed
$r = Forward::Routes->new->format('html','');
$r->add_route('foo');
$r->add_route(':foo/:bar');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

# now paths with wrong format
$m = $r->match(get => 'foo.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/there.jpeg');
is $m, undef;
