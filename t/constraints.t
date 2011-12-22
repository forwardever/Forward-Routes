use strict;
use warnings;
use Test::More tests => 16;
use lib 'lib';
use Forward::Routes;


#############################################################################
### constraints

### simple route
my $r = Forward::Routes->new;
$r->add_route('articles/:id')->constraints(id => qr/\d+/)->name('article');


# match
my $m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(get => 'articles/abc1');
ok not defined $m;

$m = $r->match(get => 'articles/123');
is_deeply $m->[0]->params => {id => 123};


# path building
my $e = eval {$r->build_path('article')->{path}};
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('article', id => 'abc')->{path}};
like $@ => qr/Param 'id' fails a constraint/;
undef $e;

is $r->build_path('article', id => 123)->{path} => 'articles/123';



### multiple parameters
$r = Forward::Routes->new;
$r->add_route('articles/:id/:comment')->constraints(id => qr/\d+/, comment => qr/[a-z]{1,2}/)->name('article');

# match
$m = $r->match(get => 'articles/abc/abc');
ok not defined $m;

$m = $r->match(get => 'articles/123/abc');
ok not defined $m;

$m = $r->match(get => 'articles/abc/ab');
ok not defined $m;

$m = $r->match(get => 'articles/123/ab');
is_deeply $m->[0]->params => {id => 123, comment => 'ab'};


# path building
$e = eval {$r->build_path('article')->{path}};
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('article', id => '123')->{path}};
like $@ => qr/Required param 'comment' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('article', comment => 'ab')->{path}};
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('article', id => 'abc', comment => 'ab')->{path}};
like $@ => qr/Param 'id' fails a constraint/;
undef $e;

$e = eval {$r->build_path('article', id => '123', comment => 'abc')->{path}};
like $@ => qr/Param 'comment' fails a constraint/;
undef $e;

is $r->build_path('article', id => 123, comment => 'ab')->{path} => 'articles/123/ab';
