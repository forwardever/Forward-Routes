#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 52;


#############################################################################
### nested resources

my $r = Forward::Routes->new;

my $ads = $r->add_resources('magazines')->add_resources('ads');

my $m = $r->match(get => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'index', magazines_id => 1};

$m = $r->match(get => 'magazines/1/ads/new');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create_form', magazines_id => 1};

$m = $r->match(post => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create', magazines_id => 1};

$m = $r->match(get => 'magazines/1/ads/4');
is_deeply $m->[0]->params => {controller => 'ads', action => 'show', magazines_id => 1, id => 4};

$m = $r->match(get => 'magazines/1/ads/5/edit');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update_form', magazines_id => 1, id => 5};

$m = $r->match(put => 'magazines/1/ads/2');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update', magazines_id => 1, id => 2};

$m = $r->match(delete => 'magazines/0/ads/1');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete', magazines_id => 0, id => 1};

$m = $r->match(get => 'magazines/11/ads/12/delete');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete_form', magazines_id => 11, id => 12};


# magazine routes WON'T work

$m = $r->match(get => 'magazines');
is $m, undef;

$m = $r->match(get => 'magazines/new');
is $m, undef;

$m = $r->match(post => 'magazines');
is $m, undef;

$m = $r->match(get => 'magazines/1');
is $m, undef;

$m = $r->match(get => 'magazines/1/edit');
is $m, undef;

$m = $r->match(get => 'magazines/1/delete');
is $m, undef;

$m = $r->match(put => 'magazines/1');
is $m, undef;

$m = $r->match(delete => 'magazines/1');
is $m, undef;


# build path
is $r->build_path('magazines_ads_index', magazines_id => 3)->{path} => 'magazines/3/ads';
is $r->build_path('magazines_ads_index', magazines_id => 3)->{method} => 'get';

is $r->build_path('magazines_ads_create_form', magazines_id => 4)->{path} => 'magazines/4/ads/new';
is $r->build_path('magazines_ads_create_form', magazines_id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_create', magazines_id => 5)->{path} => 'magazines/5/ads';
is $r->build_path('magazines_ads_create', magazines_id => 5)->{method} => 'post';

is $r->build_path('magazines_ads_show', magazines_id => 3, id => 4)->{path} => 'magazines/3/ads/4';
is $r->build_path('magazines_ads_show', magazines_id => 3, id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_update', magazines_id => 0, id => 4)->{path} => 'magazines/0/ads/4';
is $r->build_path('magazines_ads_update', magazines_id => 0, id => 4)->{method} => 'put';

is $r->build_path('magazines_ads_delete', magazines_id => 4, id => 0)->{path} => 'magazines/4/ads/0';
is $r->build_path('magazines_ads_delete', magazines_id => 4, id => 0)->{method} => 'delete';

is $r->build_path('magazines_ads_update_form', magazines_id => 3, id => 4)->{path} => 'magazines/3/ads/4/edit';
is $r->build_path('magazines_ads_update_form', magazines_id => 3, id => 4)->{method} => 'get';

is $r->build_path('magazines_ads_delete_form', magazines_id => 3, id => 4)->{path} => 'magazines/3/ads/4/delete';
is $r->build_path('magazines_ads_delete_form', magazines_id => 3, id => 4)->{method} => 'get';


my $e = eval {$r->build_path('magazines_ads_index')->{path}; };
like $@ => qr/Required param 'magazines_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_show')->{path}; };
like $@ => qr/Required param 'magazines_id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_show', magazines_id => 3)->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('magazines_ads_delete_form', magazines_id => 3)->{path}; };
like $@ => qr/Required param 'id' was not passed when building a path/;
undef $e;



### now add magazines as a separate resource

$r->add_resources('magazines');

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



# ... and nested resource still works

$m = $r->match(get => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'index', magazines_id => 1};

$m = $r->match(get => 'magazines/1/ads/new');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create_form', magazines_id => 1};

$m = $r->match(post => 'magazines/1/ads');
is_deeply $m->[0]->params => {controller => 'ads', action => 'create', magazines_id => 1};

$m = $r->match(get => 'magazines/1/ads/4');
is_deeply $m->[0]->params => {controller => 'ads', action => 'show', magazines_id => 1, id => 4};

$m = $r->match(get => 'magazines/1/ads/5/edit');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update_form', magazines_id => 1, id => 5};

$m = $r->match(put => 'magazines/1/ads/2');
is_deeply $m->[0]->params => {controller => 'ads', action => 'update', magazines_id => 1, id => 2};

$m = $r->match(delete => 'magazines/0/ads/1');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete', magazines_id => 0, id => 1};

$m = $r->match(get => 'magazines/11/ads/12/delete');
is_deeply $m->[0]->params => {controller => 'ads', action => 'delete_form', magazines_id => 11, id => 12};
