#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 38;


#############################################################################
### nested resources

my $r = Forward::Routes->new;

my $ads = $r->add_resources('magazines')->add_resources('ads');

my $m = $r->match(get => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'index', magazine_id => 1};

$m = $r->match(get => 'magazines/1/ads/new');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create_form', magazine_id => 1};

$m = $r->match(post => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create', magazine_id => 1};

$m = $r->match(get => 'magazines/1/ads/4');
is_deeply $m->[0]->params => {controller => 'ads', action => 'show', magazine_id => 1, id => 4};

$m = $r->match(get => 'magazines/1/ads/5/edit');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update_form', magazine_id => 1, id => 5};

$m = $r->match(put => 'magazines/1/ads/2');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update', magazine_id => 1, id => 2};

$m = $r->match(delete => 'magazines/0/ads/1');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete', magazine_id => 0, id => 1};

$m = $r->match(get => 'magazines/11/ads/12/delete');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete_form', magazine_id => 11, id => 12};

$m = $r->match(post => 'magazines/1.2/ads');
is $m, undef;


# magazine routes also work

$m = $r->match(get => 'magazines');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'index'};

$m = $r->match(get => 'magazines/new');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'create_form'};

$m = $r->match(post => 'magazines');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'create'};

$m = $r->match(get => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'show', id => 1};

$m = $r->match(get => 'magazines/1/edit');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'update_form', id => 1};

$m = $r->match(get => 'magazines/1/delete');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'delete_form', id => 1};

$m = $r->match(put => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'update', id => 1};

$m = $r->match(delete => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'magazines', action => 'delete', id => 1};


# build path
is $r->build_path('magazines_ads_index', magazine_id => 3)->{path} => 'magazines/3/ads';
is $r->build_path('magazines_ads_index', magazine_id => 3)->{method} => 'get';

is $r->build_path('magazines_ads_create_form', magazine_id => 4)->{path} => 'magazines/4/ads/new';
is $r->build_path('magazines_ads_create_form', magazine_id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_create', magazine_id => 5)->{path} => 'magazines/5/ads';
is $r->build_path('magazines_ads_create', magazine_id => 5)->{method} => 'post';

is $r->build_path('magazines_ads_show', magazine_id => 3, id => 4)->{path} => 'magazines/3/ads/4';
is $r->build_path('magazines_ads_show', magazine_id => 3, id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_update', magazine_id => 0, id => 4)->{path} => 'magazines/0/ads/4';
is $r->build_path('magazines_ads_update', magazine_id => 0, id => 4)->{method} => 'put';

is $r->build_path('magazines_ads_delete', magazine_id => 4, id => 0)->{path} => 'magazines/4/ads/0';
is $r->build_path('magazines_ads_delete', magazine_id => 4, id => 0)->{method} => 'delete';

is $r->build_path('magazines_ads_update_form', magazine_id => 3, id => 4)->{path} => 'magazines/3/ads/4/edit';
is $r->build_path('magazines_ads_update_form', magazine_id => 3, id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_delete_form', magazine_id => 3, id => 4)->{path} => 'magazines/3/ads/4/delete';
is $r->build_path('magazines_ads_delete_form', magazine_id => 3, id => 4)->{method} => 'get';


my $e = eval {$r->build_path('magazines_ads_index')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_show')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_show', magazine_id => 3)->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_delete_form', magazine_id => 3)->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;


### deeper nesting
$r = Forward::Routes->new;

my $stats = $r->add_resources('magazines')->add_resources('ads')->add_resources('stats');

$m = $r->match(get => 'magazines/1/ads/4/stats/7');
is_deeply $m->[0]->params => {controller => 'stats', action => 'show', magazine_id => 1, ad_id => 4, id => 7};
