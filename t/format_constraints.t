#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 45;


#############################################################################
### format

### no format constraint, but format passed
my $r = Forward::Routes->new;
$r->add_route('foo');
$r->add_route(':foo/:bar');

my $m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there.html'};



### one format constraint
$r = Forward::Routes->new->format('html');
$r->add_route('foo')->name('one');
$r->add_route(':foo/:bar')->name('two');

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


# build path
is $r->build_path('one')->{path}, 'foo.html';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2.html';
is $r->build_path('two', foo => 0, bar => 2)->{path}, '0/2.html';


### pass empty format explicitly
$r = Forward::Routes->new->format('');
$r->add_route('foo')->name('one');
$r->add_route(':foo/:bar')->name('two');

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => ''};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};


# now paths with format
$m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is $m, undef;


# build path
is $r->build_path('one')->{path}, 'foo';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2';



### pass undef format (no contraint validation)
$r = Forward::Routes->new->format(undef);
$r->add_route('foo')->name('one');
$r->add_route(':foo/:bar')->name('two');

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

# now paths with format
$m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there.html'};


# build path
is $r->build_path('one')->{path}, 'foo';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2';



### multiple format constraints
$r = Forward::Routes->new->format('html','xml');
$r->add_route('foo')->name('one');
$r->add_route(':foo/:bar')->name('two');

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


# build path
is $r->build_path('one')->{path}, 'foo.html';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2.html';




### multiple format constraints, with empty format allowed
$r = Forward::Routes->new->format('html','');
$r->add_route('foo')->name('one');
$r->add_route(':foo/:bar')->name('two');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => ''};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};

# now paths with wrong format
$m = $r->match(get => 'foo.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/there.jpeg');
is $m, undef;


# build path
is $r->build_path('one')->{path}, 'foo.html';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2.html';