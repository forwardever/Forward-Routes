#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 436;

#############################################################################
### empty

my $r = Forward::Routes->new;
ok $r;
ok $r->isa('Forward::Routes');


#############################################################################
### add_route

$r = Forward::Routes->new;
$r = $r->add_route('foo');
is ref $r, 'Forward::Routes';


#############################################################################
### initialize

$r = Forward::Routes->new;

is $r->{method}, undef;
is $r->{defaults}, undef;
is $r->{prefix}, undef;
is $r->{name}, undef;
is $r->{to}, undef;
is $r->{pattern}, undef;


#############################################################################
### unbalanced_parentheses

# Open
$r = Forward::Routes->new;
$r->add_route('(');
eval { $r->match(get => 'foo/bar') };
like $@ => qr/are not balanced/;

# Close
$r = Forward::Routes->new;
$r->add_route(')');
eval { $r->match(get => 'foo/bar') };
like $@ => qr/are not balanced/;

# Close Optional
$r = Forward::Routes->new;
$r->add_route(')?');
eval { $r->match(get => 'foo/bar') };
like $@ => qr/are not balanced/;


#############################################################################
### match
$r = Forward::Routes->new;
$r->add_route('foo');
$r->add_route(':foo/:bar');

my $m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};


#############################################################################
### format

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




#############################################################################
### match_root

$r = Forward::Routes->new(defaults => {foo => 1});
$m = $r->match(get => 'hello');
ok not defined $m;


#############################################################################
### match_nested_routes
$r = Forward::Routes->new;
my $pattern = $r->add_route('foo');
$pattern->add_route('bar');

$pattern = $r->add_route(':foo');
$pattern->add_route(':bar');

$m = $r->match(get => 'foo/bar');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

$m = $r->match(get => 'foo/bar/baz');
is $m, undef;

$m = $r->match(get => 'foo');
is $m, undef;

# match again (params empty again)
$m = $r->match(get => 'foo/bar');
is_deeply $m->[0]->params => {};


#############################################################################
### match_with_defaults

$r = Forward::Routes->new;
$r->add_route('articles')->defaults(controller => 'foo', action => 'bar');

$m = $r->match(get => 'articles');
is_deeply $m->[0]->params => {controller => 'foo', action => 'bar'};


#############################################################################
### match_with_to_defaults
$r = Forward::Routes->new;
$r->add_route('articles')->to('foo#bar');
$r->add_route(':controller/:action')->to('foo#bar');

$m = $r->match(get => 'articles');
is_deeply $m->[0]->params => {controller => 'foo', action => 'bar'};

# overwrite defaults
$m = $r->match(get => 'foo/baz');
is_deeply $m->[0]->params => {controller => 'foo', action => 'baz'};

$m = $r->match(get => 'hello/baz');
is_deeply $m->[0]->params => {controller => 'hello', action => 'baz'};


#############################################################################
### match_with_defaults_nested_routes

# overwrite defaults
$r = Forward::Routes->new;
my $nested = $r->add_route(':author')->defaults(author => 'foo');
$nested->add_route(':articles')->defaults(articles => 'bar');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {author => 'hello', articles => 'world'};


# default has precedence over capture in parent routes
$r = Forward::Routes->new;
$nested = $r->add_route(':author');
$nested->add_route(':articles')->defaults(author => 'foo', articles => 'bar');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {author => 'foo', articles => 'world'};


# defaults deeper in the chain have precedence over earlier defaults
$r = Forward::Routes->new;
$nested = $r->add_route('author')->defaults(comments => 'baz');
$nested->add_route('articles')->defaults(comments => 'foo');

$m = $r->match(get => 'author/articles');
is_deeply $m->[0]->params => {comments => 'foo'};


#############################################################################
### match_with_constraints

$r = Forward::Routes->new;

$r->add_route('articles/:id')->constraints(id => qr/\d+/);

$m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(get => 'articles/123');
is_deeply $m->[0]->params => {id => 123};


#############################################################################
### match_with_optional

$r = Forward::Routes->new;

$r->add_route(':year(/:month/:day)?')->name('foo');

$m = $r->match(get => '2009');
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


#############################################################################
### match_with_defaults_and_optional

$r = Forward::Routes->new;
$r->add_route(':year(/:month)?/:day')->defaults(month => 1)->name('foo');

$m = $r->match(get => '2009');
ok not defined $m;

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 1, day => 12};

$m = $r->match(get => '2009/2/3');
is_deeply $m->[0]->params => {year => 2009, month => 2, day => 3};

# build path
$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 2, day => 12)->{path}, '2009/2/12';
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/1/12';



$r = Forward::Routes->new;
$r->add_route(':year/(:month)?/:day')->defaults(month => 1)->name('foo');

$m = $r->match(get => '2009');
ok not defined $m;

$m = $r->match(get => '2009//12');
is_deeply $m->[0]->params => {year => 2009, month => 1, day => 12};

$m = $r->match(get => '2009/2/3');
is_deeply $m->[0]->params => {year => 2009, month => 2, day => 3};

# build path
$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 2, day => 12)->{path}, '2009/2/12';
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/1/12';



$r = Forward::Routes->new;
$r->add_route('world/(:country)?-(:cities)?')
  ->defaults(country => 'foo', cities => 'baz')->name('hello');

$m = $r->match(get => 'world/us-');
is_deeply $m->[0]->params => {country => 'us', cities => 'baz'};

$m = $r->match(get => 'world/-new_york');
is_deeply $m->[0]->params => {country => 'foo', cities => 'new_york'};

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/foo-new_york';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-baz';
is $r->build_path('hello')->{path}, 'world/foo-baz';


#############################################################################
### match_with_grouping

$r = Forward::Routes->new;
$r->add_route('world/(:country)-(((:cities)))')->name('foo');

$m = $r->match(get => 'world/us-');
is $m, undef;

$m = $r->match(get => 'world/-new_york');
is $m, undef;

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', country => 'us')->{path}; };
like $@ => qr/Required param 'cities' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', cities => 'new_york')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;
undef $e;

is $r->build_path('foo', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';



$r = Forward::Routes->new;
$r->add_route('world/((((((((:country)))-(((:cities)))-(:street))))))')->name('foo');

$m = $r->match(get => 'world/us-new_york');
is $m, undef;

$m = $r->match(get => 'world/us-new_york-');
is $m, undef;

$m = $r->match(get => 'world/us-new_york-52_str');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york', street => '52_str'};

$e = eval {$r->build_path('foo', country => 'us', cities => 'new_york')->{path}; };
like $@ => qr/Required param 'street' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', country => 'us', street => '52_str')->{path}; };
like $@ => qr/Required param 'cities' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', cities => 'new_york', street => 'baker_str')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;
undef $e;

is $r->build_path('foo', country => 'us', cities => 'new_york', street => '52_str')->{path}, 'world/us-new_york-52_str';


#############################################################################
### match_with_grouping_and_defaults

$r = Forward::Routes->new;
$r->add_route('world/(:country)-(:cities)')
  ->defaults(country => 'foo', cities => 'baz')->name('hello');

$m = $r->match(get => 'world/');
is $m, undef;

$m = $r->match(get => 'world/us-');
is $m, undef;

$m = $r->match(get => 'world/-new_york');
is $m, undef;

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/foo-new_york';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-baz';


#############################################################################
### match_with_optional_and_grouping

# Two captures in one optional group, no defaults
$r = Forward::Routes->new;
$r->add_route('world/((((:country)))-(:cities))?')->name('hello');

$m = $r->match(get => 'world/us-');
ok not defined $m;

$m = $r->match(get => 'world/-new_york');
ok not defined $m;

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';
is $r->build_path('hello')->{path}, 'world/';

$e = eval {$r->build_path('hello', cities => 'new_york')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('hello', country => 'us')->{path}; };
like $@ => qr/Required param 'cities' was not passed when building a path/;
undef $e;



$r = Forward::Routes->new;
$r->add_route('world/(:country)?(-and-)(:cities)?')->name('hello');

$m = $r->match(get => 'world/us-and-');
is_deeply $m->[0]->params => {country => 'us'};

$m = $r->match(get => 'world/-and-new_york');
is_deeply $m->[0]->params => {cities => 'new_york'};

$m = $r->match(get => 'world/us-and-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-and-new_york';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/-and-new_york';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-and-';
is $r->build_path('hello')->{path}, 'world/-and-';



$r = Forward::Routes->new;
$r->add_route('world/(:country)?(-and-)(:cities)?-text')->name('hello');

$m = $r->match(get => 'world/us-and--text');
is_deeply $m->[0]->params => {country => 'us'};

$m = $r->match(get => 'world/-and-new_york-text');
is_deeply $m->[0]->params => {cities => 'new_york'};

$m = $r->match(get => 'world/us-and-new_york-text');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-and-new_york-text';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/-and-new_york-text';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-and--text';
is $r->build_path('hello')->{path}, 'world/-and--text';


#############################################################################
### match_with_nestedoptional

$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';

$e = eval {$r->build_path('foo', year => 2009, day => 12)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;
undef $e;



$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?-text')->name('foo');

$m = $r->match(get => '2009-text');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12-text');
is_deeply $m->[0]->params => {year => 2009, month => 12};

$m = $r->match(get => '2009/12/10-text');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009-text';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12-text';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10-text';

$e = eval {$r->build_path('foo', year => 2009, day => 12)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;
undef $e;



$r = Forward::Routes->new;
$r->add_route(':year((/:month)?/:day)?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, day => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/12';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';

$e = eval {$r->build_path('foo', year => 2009, month => 3)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;



# more complex test 3 levels and text surrounding placeholders
$r = Forward::Routes->new;
$r->add_route('year(:year)(/month(:month)-monthend(/day(:day)(hour-(:hour)-hourend)?-dayend)?)?-text')->name('foo');

$m = $r->match(get => 'year2009-text');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => 'year2009/month11-monthend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11};

$m = $r->match(get => 'year2009/month11-monthend/day3-text');
is $m, undef;

$m = $r->match(get => 'year2009/month11-monthend/day3-dayend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3};

$m = $r->match(get => 'year2009/month11-monthend/day3hour-5-dayend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => "3hour-5"};

#$m = $r->match(get => 'year2009/month11-monthend/day3hour-5-hourend-dayend-text');
#is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3};

# build path
is $r->build_path('foo', year => 2009)->{path}, 'year2009-text';
is $r->build_path('foo', year => 2009, month => 11)->{path}, 'year2009/month11-monthend-text';
is $r->build_path('foo', year => 2009, month => 11, day => 3)->{path}, 'year2009/month11-monthend/day3-dayend-text';



# same test, but hour not optional
$r = Forward::Routes->new;
$r->add_route('year(:year)(/month(:month)-monthend(/day(:day)(hour-(:hour)-hourend)-dayend)?)?-text')->name('foo');

$m = $r->match(get => 'year2009-text');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => 'year2009/month11-monthend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11};

$m = $r->match(get => 'year2009/month11-monthend/day3-text');
is $m, undef;

$m = $r->match(get => 'year2009/month11-monthend/day3-dayend-text');
is $m, undef;

$m = $r->match(get => 'year2009/month11-monthend/day3hour-5-hourend-dayend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, hour => 5};

$m = $r->match(get => 'year2009/month11-monthend/day3hour-5--dayend-text');
is $m, undef;

# build path
is $r->build_path('foo', year => 2009)->{path}, 'year2009-text';
is $r->build_path('foo', year => 2009, month => 11)->{path}, 'year2009/month11-monthend-text';
is $r->build_path('foo', year => 2009, month => 11, day => 3, hour => 5)->{path}, 'year2009/month11-monthend/day3hour-5-hourend-dayend-text';

$e = eval {$r->build_path('foo', year => 2009, month => 3, day => 2)->{path}; };
like $@ => qr/Required param 'hour' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', year => 2009, month => 3, hour => 2)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;



# same test, but hour is nested
$r = Forward::Routes->new;
$r->add_route('year(:year)(/month(:month)m(/day(:day)d(((((/hours-(:hours)h-minutes-(:minutes)m-seconds(:seconds)s)?)?)?)))?)?-location(-country-(:country)(/city-(:city)(/street-(:street))?)?)?')->name('foo');

$m = $r->match(get => 'year2009-location');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => 'year2009/month11m-location');
is_deeply $m->[0]->params => {year => 2009, month => 11};

$m = $r->match(get => 'year2009/month11m/day3-location');
is $m, undef;

$m = $r->match(get => 'year2009/month11m/day3d-location');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3};

$m = $r->match(get => 'year2009/month11m/day3d-location-country-france');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, country => 'france'};

$m = $r->match(get => 'year2009/month11m/day3d-location-country-france/city-paris');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, country => 'france', city => 'paris'};

$m = $r->match(get => 'year2009/month11m/day3d-location-country-france/city-paris/street-test');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, country => 'france', city => 'paris', street => 'test'};

$m = $r->match(get => 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location-country-france/city-paris/street-test');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33, country => 'france', city => 'paris', street => 'test'};

$m = $r->match(get => 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33};

$m = $r->match(get => 'year2009/month11m/day3d/hours-5h-location');
is $m, undef;

$m = $r->match(get => 'year2009/month11m/day3d/minutes-27m-seconds33s-location');
is $m, undef;

# build path
is $r->build_path('foo', year => 2009)->{path}, 'year2009-location';
is $r->build_path('foo', year => 2009, month => 11)->{path}, 'year2009/month11m-location';
is $r->build_path('foo', year => 2009, month => 11, day => 3)->{path}, 'year2009/month11m/day3d-location';
is $r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33)->{path}, 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location';

$e = eval {$r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, minutes => 27)->{path}; };
like $@ => qr/Required param 'seconds' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', year => 2009, month => 11, day => 3, minutes => 27, seconds => 33)->{path}; };
like $@ => qr/Required param 'hours' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 11, day => 3, country => 'france', city => 'paris', street => 'test')->{path}, 'year2009/month11m/day3d-location-country-france/city-paris/street-test';
is $r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33, country => 'france', city => 'paris', street => 'test')->{path}, 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location-country-france/city-paris/street-test';

$e = eval {$r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, seconds => 33, country => 'france', city => 'paris', street => 'test')->{path}; };
like $@ => qr/Required param 'minutes' was not passed when building a path/;
undef $e;


#############################################################################
### match_with_nestedoptional_and_grouping

$r = Forward::Routes->new;
$r->add_route(':year(/:month/((((:day)))))?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
is $m, undef;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';

$e = eval {$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;


#############################################################################
### match_with_nestedoptional_and_defaults

$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?')->name('foo')->defaults(month => 1);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, month => 1};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009, month => 1)->{path}, '2009/1';
is $r->build_path('foo', year => 2009)->{path}, '2009/1';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, day => 10)->{path}, '2009/1/10';



$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?')->name('foo')->defaults(day => 2);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
$e = eval {$r->build_path('foo', year => 2009, day => 2)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12/2';



# same test, but optional surrounded by grouping plus some more optional grouping
$r = Forward::Routes->new;
$r->add_route(':year(/:month(((((((/:day)?)))?)?)))?')->name('foo')->defaults(day => 2);
# same as $r->add_route(':year(/:month(/:day)?)?')->name('foo')->defaults(day => 2);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path

$e = eval {$r->build_path('foo', year => 2009, day => 2)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12/2';



$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day))?')->defaults(day => 2)->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is $m, undef;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo', year => 2009, day => 1)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 1)->{path}, '2009/1/2';
is $r->build_path('foo', year => 2009, month => 1, day => 3)->{path}, '2009/1/3';



$r = Forward::Routes->new;
$r->add_route(':year((/:month)?/:day)?')->defaults(month => 1);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, month => 1};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 1, day => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};



$r = Forward::Routes->new;
$r->add_route(':year((/:month)?/:day)?')->defaults(day => 2);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, day => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};


#############################################################################
### match_nested_routes_and_method

$r = Forward::Routes->new;
$nested = $r->add_route('foo');
$nested->add_route->via('get')->defaults(test => 1)->to('foo#get');
$nested->add_route->via('post')->to('foo#post')->defaults( test => 2);
$nested->add_route->via('put')->to('foo#put');

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'post', test => 2};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'get', test => 1};

$m = $r->match(delete => 'foo');
ok not defined $m;


#############################################################################
### globbing

$r = Forward::Routes->new;
$r->add_route('photos/*other');
$r->add_route('books/*section/:title');
$r->add_route('*a/foo/*b');

$m = $r->match(get => 'photos/foo/bar/baz');
is_deeply $m->[0]->params => {other => 'foo/bar/baz'};

$m = $r->match(get => 'books/some/section/last-words-a-memoir');
is_deeply $m->[0]->params =>
  {section => 'some/section', title => 'last-words-a-memoir'};

$m = $r->match(get => 'zoo/woo/foo/bar/baz');
is_deeply $m->[0]->params => {a => 'zoo/woo', b => 'bar/baz'};


#############################################################################
### method

$r = Forward::Routes->new;

$r->add_route('articles');
ok $r->match(get => 'articles');

$r->add_route('logout')->via('get');
ok $r->match(get => 'logout');
ok !$r->match(post => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('GET');
ok $r->match(get => 'logout');
ok $r->match(GET => 'logout');
ok !$r->match(post => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('get');
ok $r->match(GET => 'logout');
ok !$r->match(POST => 'logout');

$r = Forward::Routes->new;
$r->add_route('photos/:id', method => [qw/get post/]);
ok $r->match(get => 'photos/1');
ok $r->match(post => 'photos/1');
ok !$r->match(head => 'photos/1');


#############################################################################
### via
$r = Forward::Routes->new;

$r->add_route('logout')->via('get');
ok $r->match(get => 'logout');
ok !$r->match(post => 'logout');

$r->add_route('photos/:id')->via([qw/get post/]);
ok $r->match(get => 'photos/1');
ok $r->match(post => 'photos/1');
ok !$r->match(head => 'photos/1');


$r = Forward::Routes->new;
$r->add_route('logout', via => 'put');

ok $r->match(put => 'logout');
ok !$r->match(post => 'logout');


#############################################################################
### bridges

$r = Forward::Routes->new;
my $bridge = $r->bridge('admin')->to('check#authentication');
$bridge->add_route('foo')->to('no#placeholders');
$bridge->add_route(':foo/:bar')->to('two#placeholders');

$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'admin/foo');
is_deeply $m->[0]->params, {controller => 'check', action => 'authentication'};
is $m->[0]->is_bridge, 1;
is_deeply $m->[1]->params, {controller => 'no', action => 'placeholders'};
is $m->[1]->is_bridge, undef;

$m = $r->match(get => '/admin/hello/there');
is_deeply $m->[0]->params, {controller => 'check', action => 'authentication'};
is_deeply $m->[1]->params, {controller => 'two', action => 'placeholders',
  foo => 'hello', bar => 'there'};


#############################################################################
### chained

# Simple
$r = Forward::Routes->new;

my $articles = $r->add_route('articles/:id')
  ->defaults(first_name => 'foo', last_name => 'bar')
  ->constraints(id => qr/\d+/)
  ->name('hot')
  ->to('hello#world')
  ->via('get','post');

is ref $articles, 'Forward::Routes';

$m = $r->match(post => 'articles/123');
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar', id => 123,
  controller => 'hello', action => 'world'};
is $r->build_path('hot', id => 234)->{path}, 'articles/234';

$m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(put => 'articles/123');
ok not defined $m;


# Passing hash and array refs (using method instead of via)
$r = Forward::Routes->new;

$articles = $r->add_route('articles/:id')
  ->defaults({first_name => 'foo', last_name => 'bar'})
  ->constraints({id => qr/\d+/})
  ->method(['get','post']);

is ref $articles, 'Forward::Routes';

$m = $r->match(post => 'articles/123');
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar', id => 123};

$m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(put => 'articles/123');
ok not defined $m;



#############################################################################
### resource

$r = Forward::Routes->new;

$r->add_resource('geocoder');

$m = $r->match(get => 'geocoder/new');
is_deeply $m->[0]->params => {controller => 'geocoder', action => 'create_form'};

$m = $r->match(post => 'geocoder');
is_deeply $m->[0]->params => {controller => 'geocoder', action => 'create'};

$m = $r->match(get => 'geocoder');
is_deeply $m->[0]->params => {controller => 'geocoder', action => 'show'};

$m = $r->match(get => 'geocoder/edit');
is_deeply $m->[0]->params => {controller => 'geocoder', action => 'update_form'};

$m = $r->match(put => 'geocoder');
is_deeply $m->[0]->params => {controller => 'geocoder', action => 'update'};

$m = $r->match(delete => 'geocoder');
is_deeply $m->[0]->params => {controller => 'geocoder', action => 'delete'};


is ref $r->find_route('geocoder_create_form'), 'Forward::Routes';
is $r->find_route('geocoder_foo'), undef;
is $r->find_route('geocoder_create_form')->name, 'geocoder_create_form';
is $r->find_route('geocoder_create')->name, 'geocoder_create';
is $r->find_route('geocoder_show')->name, 'geocoder_show';
is $r->find_route('geocoder_update_form')->name, 'geocoder_update_form';
is $r->find_route('geocoder_update')->name, 'geocoder_update';
is $r->find_route('geocoder_delete')->name, 'geocoder_delete';

is $r->build_path('geocoder_create_form')->{path} => 'geocoder/new';
is $r->build_path('geocoder_create')->{path} => 'geocoder';
is $r->build_path('geocoder_show', id => 456)->{path} => 'geocoder';
is $r->build_path('geocoder_update_form', id => 789)->{path} => 'geocoder/edit';
is $r->build_path('geocoder_update', id => 987)->{path} => 'geocoder';
is $r->build_path('geocoder_delete', id => 654)->{path} => 'geocoder';

#############################################################################
### resources

$r = Forward::Routes->new;
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index'};

$m = $r->match(get => 'photos2');
is $m, undef;

$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create_form'};

$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create'};

$m = $r->match(get => 'photos/1');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'show', id => 1};

$m = $r->match(get => 'photos/1/edit');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'update_form', id => 1};

$m = $r->match(get => 'photos/1/delete');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'delete_form', id => 1};

$m = $r->match(put => 'photos/1');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'update', id => 1};

$m = $r->match(delete => 'photos/1');
is_deeply $m->[0]->params => {
    controller => 'photos',
    action     => 'delete',
    id         => 1
};

is ref $r->find_route('photos_index'), 'Forward::Routes';
is $r->find_route('photos_foo'), undef;
is $r->find_route('photos_index')->name, 'photos_index';
is $r->find_route('photos_create_form')->name, 'photos_create_form';
is $r->find_route('photos_create')->name, 'photos_create';
is $r->find_route('photos_show')->name, 'photos_show';
is $r->find_route('photos_update_form')->name, 'photos_update_form';
is $r->find_route('photos_update')->name, 'photos_update';
is $r->find_route('photos_delete')->name, 'photos_delete';
is $r->find_route('photos_delete_form')->name, 'photos_delete_form';

is $r->build_path('photos_index')->{path} => 'photos';
is $r->build_path('photos_create_form')->{path} => 'photos/new';
is $r->build_path('photos_create')->{path} => 'photos';
is $r->build_path('photos_show', id => 456)->{path} => 'photos/456';
is $r->build_path('photos_update_form', id => 789)->{path} => 'photos/789/edit';
is $r->build_path('photos_update', id => 987)->{path} => 'photos/987';
is $r->build_path('photos_delete', id => 654)->{path} => 'photos/654';
is $r->build_path('photos_delete_form', id => 222)->{path} => 'photos/222/delete';

is $r->build_path('photos_index')->{method} => 'get';
is $r->build_path('photos_create_form')->{method} => 'get';
is $r->build_path('photos_create')->{method} => 'post';
is $r->build_path('photos_show', id => 456)->{method} => 'get';
is $r->build_path('photos_update_form', id => 789)->{method} => 'get';
is $r->build_path('photos_update', id => 987)->{method} => 'put';
is $r->build_path('photos_delete', id => 654)->{method} => 'delete';
is $r->build_path('photos_delete_form', id => 222)->{method} => 'get';


#############################################################################
### resources_with_format

$r = Forward::Routes->new->format('html');
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index', format => 'html'};

$m = $r->match(get => 'photos/new.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create_form', format => 'html'};

$m = $r->match(post => 'photos.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create', format => 'html'};

$m = $r->match(get => 'photos/1.html');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'show', id => 1, format => 'html'};

$m = $r->match(get => 'photos/1/edit.html');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'update_form', id => 1, format => 'html'};

$m = $r->match(put => 'photos/1.html');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'update', id => 1, format => 'html'};

$m = $r->match(delete => 'photos/1.html');
is_deeply $m->[0]->params => {
    controller => 'photos',
    action     => 'delete',
    id         => 1,
    format => 'html'
};



### empty format
$r = Forward::Routes->new->format('');
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index'};

$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create_form'};

$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create'};

$m = $r->match(get => 'photos/1');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'show', id => 1};

$m = $r->match(get => 'photos/1/edit');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'update_form', id => 1};

$m = $r->match(get => 'photos/1/delete');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'delete_form', id => 1};

$m = $r->match(put => 'photos/1');
is_deeply $m->[0]->params =>
  {controller => 'photos', action => 'update', id => 1};

$m = $r->match(delete => 'photos/1');
is_deeply $m->[0]->params => {
    controller => 'photos',
    action     => 'delete',
    id         => 1
};


# wrong format
$r = Forward::Routes->new->format('');
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos.html');
is $m, undef;

$m = $r->match(get => 'photos/new.html');
is $m, undef;

$m = $r->match(post => 'photos.html');
is $m, undef;

$m = $r->match(get => 'photos/1.html');
is $m, undef;

$m = $r->match(get => 'photos/1/edit.html');
is $m, undef;

$m = $r->match(put => 'photos/1.html');
is $m, undef;

$m = $r->match(delete => 'photos/1.html');
is $m, undef;



# wrong format
$r = Forward::Routes->new->format('html');
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos.xml');
is $m, undef;

$m = $r->match(get => 'photos/new.xml');
is $m, undef;

$m = $r->match(post => 'photos.xml');
is $m, undef;

$m = $r->match(get => 'photos/1.xml');
is $m, undef;

$m = $r->match(get => 'photos/1/edit.xml');
is $m, undef;

$m = $r->match(put => 'photos/1.xml');
is $m, undef;

$m = $r->match(delete => 'photos/1.xml');
is $m, undef;


#############################################################################
### index_routes_by_name

$r = Forward::Routes->new;
$r->add_resources('photos');

is $r->find_route('photos_foo'), undef;
is $r->{routes_by_name}->{photos_foo}, undef;

is $r->{routes_by_name}->{photos_index}, undef;
is $r->find_route('photos_index')->name, 'photos_index';
is $r->{routes_by_name}->{photos_index}->name, 'photos_index';


#############################################################################
### nested_resources

$r = Forward::Routes->new;

my $magazines = $r->add_resources('magazines');

$magazines->add_resources('ads');

$m = $r->match(get => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'index', magazines_id => 1};

$m = $r->match(get => 'magazines/1/ads/new');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create_form', magazines_id => 1};

$m = $r->match(post => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create', magazines_id => 1};

$m = $r->match(get => 'magazines/1/ads/4');
is_deeply $m->[0]->params => {controller => 'ads', action => 'show', magazines_id => 1, ads_id => 4};

$m = $r->match(get => 'magazines/1/ads/5/edit');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update_form', magazines_id => 1, ads_id => 5};

$m = $r->match(put => 'magazines/1/ads/2');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update', magazines_id => 1, ads_id => 2};

$m = $r->match(delete => 'magazines/0/ads/1');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete', magazines_id => 0, ads_id => 1};

$m = $r->match(get => 'magazines/11/ads/12/delete');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete_form', magazines_id => 11, ads_id => 12};


# magazine routes still work

$m = $r->match(get => 'magazines');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'index'};

$m = $r->match(get => 'magazines/new');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'create_form'};

$m = $r->match(post => 'magazines');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'create'};

$m = $r->match(get => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'show', magazines_id => 1};

$m = $r->match(get => 'magazines/1/edit');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'update_form', magazines_id => 1};

$m = $r->match(get => 'magazines/1/delete');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'delete_form', magazines_id => 1};

$m = $r->match(put => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'update', magazines_id => 1};

$m = $r->match(delete => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'delete', magazines_id => 1};


# build path
is $r->build_path('ads_index', magazines_id => 3)->{path} => 'magazines/3/ads';
is $r->build_path('ads_create_form', magazines_id => 4)->{path} => 'magazines/4/ads/new';
is $r->build_path('ads_create', magazines_id => 5)->{path} => 'magazines/5/ads';
is $r->build_path('ads_show', magazines_id => 3, ads_id => 4)->{path} => 'magazines/3/ads/4';
is $r->build_path('ads_update', magazines_id => 0, ads_id => 4)->{path} => 'magazines/0/ads/4';
is $r->build_path('ads_delete', magazines_id => 4, ads_id => 0)->{path} => 'magazines/4/ads/0';
is $r->build_path('ads_update_form', magazines_id => 3, ads_id => 4)->{path} => 'magazines/3/ads/4/edit';
is $r->build_path('ads_delete_form', magazines_id => 3, ads_id => 4)->{path} => 'magazines/3/ads/4/delete';

$e = eval {$r->build_path('ads_index')->{path}; };
like $@ => qr/Required param 'magazines_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('ads_show')->{path}; };
like $@ => qr/Required param 'magazines_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('ads_show', magazines_id => 3)->{path}; };
like $@ => qr/Required param 'ads_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('ads_delete_form', magazines_id => 3)->{path}; };
like $@ => qr/Required param 'ads_id' was not passed when building a path/;
undef $e;



#############################################################################
### prefix

$r = Forward::Routes->new;
$r->add_route('prefixed', to => 'foo#bar', prefix => 'hello');

my $admin = $r->prefixed_with('admin');
$admin->add_route('foo', to => 'foo#bar');

ok !$r->match(get => 'foo');

$m = $r->match(get => 'admin/foo');

#is_deeply $m->[0]->params => {controller => 'admin-foo', action => 'bar'};

$m = $r->match(get => 'hello/prefixed');

#is_deeply $m->[0]->params => {controller => 'hello-foo', action => 'bar'};


#############################################################################
### build_path

$r = Forward::Routes->new;
$r->add_route('foo',       name => 'one');
$r->add_route(':foo/:bar', name => 'two');
$r->add_route(
    'articles/:id',
    constraints => {id => qr/\d+/},
    name        => 'article'
);
$r->add_route('photos/*other',                   name => 'glob1');
$r->add_route('books/*section/:title',           name => 'glob2');
$r->add_route('*a/foo/*b',                       name => 'glob3');
$r->add_route('archive/:year(/:month/:day)?',    name => 'optional1');
$r->add_route('archive/:year(/:month(/:day)?)?', name => 'optional2');


$e = eval {$r->build_path('unknown')->{path}; };
like $@ => qr/Unknown name 'unknown' used to build a path/;
undef $e;

$e = eval {$r->build_path('article')->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('glob2')->{path}; };
like $@ =>
  qr/Required glob param 'section' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('article', id => 'abc')->{path}; };
like $@ => qr/Param 'id' fails a constraint/;
undef $e;

is $r->build_path('one')->{path} => 'foo';
is $r->build_path('two', foo => 'foo', bar => 'bar')->{path} => 'foo/bar';
is $r->build_path('article', id => 123)->{path} => 'articles/123';
is $r->build_path('glob1', other => 'foo/bar/baz')->{path} =>
  'photos/foo/bar/baz';
is $r->build_path(
    'glob2',
    section => 'fiction/fantasy',
    title   => 'hello'
)->{path} => 'books/fiction/fantasy/hello';
is $r->build_path('glob3', a => 'foo/bar', b => 'baz/zab')->{path} =>
  'foo/bar/foo/baz/zab';

is $r->build_path('optional1', year => 2010)->{path} => 'archive/2010';

$e = eval {$r->build_path('optional1', year => 2010, month => 5)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('optional1', year => 2010, month => 5, day => 4)->{path} =>
  'archive/2010/5/4';

is $r->build_path('optional2', year => 2010)->{path} => 'archive/2010';
is $r->build_path('optional2', year => 2010, month => 3)->{path} =>
  'archive/2010/3';
is $r->build_path('optional2', year => 2010, month => 3, day => 4)->{path} =>
  'archive/2010/3/4';


1;
