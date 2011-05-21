#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 21;


#############################################################################
# singular resources with namespace prefix

my $r = Forward::Routes->new;

$r->add_singular_resources('geocoder', -namespace => 'admin', 'contact', 'test');

my $m = $r->match(get => 'geocoder/new');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'create_form'};

$m = $r->match(post => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'create'};

$m = $r->match(get => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'show'};


is $r->build_path('geocoder_create_form')->{path} => 'geocoder/new';
is $r->build_path('geocoder_create')->{path} => 'geocoder';
is $r->build_path('geocoder_show', id => 456)->{path} => 'geocoder';



### now contact

$m = $r->match(get => 'contact/new');
is_deeply $m->[0]->params => {controller => 'Admin::Contact', action => 'create_form'};

$m = $r->match(post => 'contact');
is_deeply $m->[0]->params => {controller => 'Admin::Contact', action => 'create'};

$m = $r->match(get => 'contact');
is_deeply $m->[0]->params => {controller => 'Admin::Contact', action => 'show'};

$m = $r->match(get => 'contact/edit');
is_deeply $m->[0]->params => {controller => 'Admin::Contact', action => 'update_form'};

$m = $r->match(put => 'contact');
is_deeply $m->[0]->params => {controller => 'Admin::Contact', action => 'update'};

$m = $r->match(delete => 'contact');
is_deeply $m->[0]->params => {controller => 'Admin::Contact', action => 'delete'};


is $r->build_path('admin_contact_create_form')->{path} => 'contact/new';
is $r->build_path('admin_contact_create')->{path} => 'contact';
is $r->build_path('admin_contact_show', id => 456)->{path} => 'contact';
is $r->build_path('admin_contact_update_form', id => 789)->{path} => 'contact/edit';
is $r->build_path('admin_contact_update', id => 987)->{path} => 'contact';
is $r->build_path('admin_contact_delete', id => 654)->{path} => 'contact';


# make sure that admin does not match (it is just the namespace value):
$m = $r->match(get => 'admin');
is $m, undef;


### now "test"
$m = $r->match(get => 'test/new');
is_deeply $m->[0]->params => {controller => 'Admin::Test', action => 'create_form'};

is $r->build_path('admin_test_create_form')->{path} => 'test/new';


