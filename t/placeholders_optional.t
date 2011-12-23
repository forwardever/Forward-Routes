use strict;
use warnings;
use Test::More tests => 38;
use lib 'lib';
use Forward::Routes;



#############################################################################
### optional placeholders

my $r = Forward::Routes->new;

$r->add_route(':year(/:month/:day)?')->name('foo');

my $m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
ok !defined $m;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};


# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';

my $e = eval {$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';



$r = Forward::Routes->new;
$r->add_route(':year(/:month)?/:day')->name('foo');

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, day => 12};

$m = $r->match(get => '2009/12/2');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

# build path
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/12';

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, day => 2, month => 12)->{path}, '2009/12/2';



$r = Forward::Routes->new;
$r->add_route(':year/(:month)?/:day')->name('foo');

$m = $r->match(get => '2009/12');
ok not defined $m;

$m = $r->match(get => '2009/12/2');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

$m = $r->match(get => '2009//2');
is_deeply $m->[0]->params => {year => 2009, day => 2};

# build path
$e = eval{$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 2)->{path}, '2009/12/2';
is $r->build_path('foo', year => 2009, day => 2)->{path}, '2009//2';



$r = Forward::Routes->new;
$r->add_route(':year/month(:month)?/:day')->name('foo');

$m = $r->match(get => '2009/12/2');
ok not defined $m;

$m = $r->match(get => '2009/month/2');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/month08/2');
is_deeply $m->[0]->params => {year => 2009, month => '08', day => 2};

# build path
is $r->build_path('foo', year => 2009, month => 12, day => 2)->{path}, '2009/month12/2';
is $r->build_path('foo', year => 2009, day => 2)->{path}, '2009/month/2';
is $r->build_path('foo', year => 2009, month => '08', day => 2)->{path}, '2009/month08/2';



$r = Forward::Routes->new;
$r->add_route('/hello/world(-:city)?')->name('foo');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/world-paris');
is_deeply $m->[0]->params => {city => 'paris'};

# build path
is $r->build_path('foo', city => "berlin")->{path}, 'hello/world-berlin';
is $r->build_path('foo')->{path}, 'hello/world';



# group city
$r = Forward::Routes->new;
$r->add_route('/hello/world(-(:city))?')->name('foo');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/world-paris');
is_deeply $m->[0]->params => {city => 'paris'};

# build path
is $r->build_path('foo', city => "berlin")->{path}, 'hello/world-berlin';
is $r->build_path('foo')->{path}, 'hello/world';



$r = Forward::Routes->new;
$r->add_route('world/(:country)?-(:cities)?')->name('hello');

$m = $r->match(get => 'world/us-');
is_deeply $m->[0]->params => {country => 'us'};

$m = $r->match(get => 'world/-new_york');
is_deeply $m->[0]->params => {cities => 'new_york'};

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/-new_york';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-';
is $r->build_path('hello')->{path}, 'world/-';
