#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 27;



#############################################################################
### plural resources with namespace prefix

my $r = Forward::Routes->new;
$r->add_resources('photos', -namespace => 'admin', 'users', 'prices');


# test routes withOUT namespace prefix
my $m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index'};
$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create_form'};
$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create'};


is $r->build_path('photos_index')->{path} => 'photos';
is $r->build_path('photos_create_form')->{path} => 'photos/new';
is $r->build_path('photos_create')->{path} => 'photos';


is $r->build_path('photos_index')->{method} => 'get';
is $r->build_path('photos_create_form')->{method} => 'get';
is $r->build_path('photos_create')->{method} => 'post';



# adjusted controller
$m = $r->match(get => 'users');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'index'};

$m = $r->match(get => 'users/new');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'create_form'};

$m = $r->match(post => 'users');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'create'};

$m = $r->match(get => 'users/1');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'show', id => 1};

$m = $r->match(get => 'users/1/edit');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'update_form', id => 1};

$m = $r->match(get => 'users/1/delete');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'delete_form', id => 1};

$m = $r->match(put => 'users/1');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'update', id => 1};

$m = $r->match(delete => 'users/1');
is_deeply $m->[0]->params => {controller => 'admin::users', action => 'delete', id => 1};


# path building with name prefix
is $r->build_path('admin_users_index')->{path} => 'users';
is $r->build_path('admin_users_create_form')->{path} => 'users/new';
is $r->build_path('admin_users_create')->{path} => 'users';
is $r->build_path('admin_users_show', id => 456)->{path} => 'users/456';
is $r->build_path('admin_users_update_form', id => 789)->{path} => 'users/789/edit';
is $r->build_path('admin_users_update', id => 987)->{path} => 'users/987';
is $r->build_path('admin_users_delete', id => 654)->{path} => 'users/654';
is $r->build_path('admin_users_delete_form', id => 222)->{path} => 'users/222/delete';


# also works for prices
$m = $r->match(get => 'prices');
is_deeply $m->[0]->params => {controller => 'admin::prices', action => 'index'};

is $r->build_path('admin_prices_index')->{path} => 'prices';

