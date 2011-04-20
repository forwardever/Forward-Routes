#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 68;


#############################################################################
### resources with format constraint

### no format constraint (defaults to format ''), but format passed

my $r = Forward::Routes->new;
$r->add_resources('users','photos','tags');

my $m = $r->match(get => 'photos.html');
is $m, undef;

$m = $r->match(get => 'photos/new.html');
is $m, undef;

$m = $r->match(post => 'photos.html');
is $m, undef;

$m = $r->match(get => 'photos/1.html');
is $m, undef;

$m = $r->match(get => 'photos/1/edit.html');
is $m, undef;

$m = $r->match(get => 'photos/1/delete.html');
is $m, undef;

$m = $r->match(put => 'photos/1.html');
is $m, undef;

$m = $r->match(delete => 'photos/1.html');
is $m, undef;



### format constraint

$r = Forward::Routes->new->format('html');
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index', format => 'html'};

$m = $r->match(get => 'photos/new.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create_form', format => 'html'};

$m = $r->match(post => 'photos.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create', format => 'html'};

$m = $r->match(get => 'photos/1.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'show', id => 1, format => 'html'};

$m = $r->match(get => 'photos/1/edit.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'update_form', id => 1, format => 'html'};

$m = $r->match(put => 'photos/1.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'update', id => 1, format => 'html'};

$m = $r->match(delete => 'photos/1.html');
is_deeply $m->[0]->params => {controller => 'photos', action => 'delete', id => 1, format => 'html'};


$m = $r->match(get => 'photos');
is $m, undef;

$m = $r->match(get => 'photos/new');
is $m, undef;

$m = $r->match(post => 'photos');
is $m, undef;

$m = $r->match(get => 'photos/1');
is $m, undef;

$m = $r->match(get => 'photos/1/edit');
is $m, undef;

$m = $r->match(put => 'photos/1');
is $m, undef;

$m = $r->match(delete => 'photos/1');
is $m, undef;


is $r->build_path('photos_index')->{path} => 'photos.html';
is $r->build_path('photos_create_form')->{path} => 'photos/new.html';
is $r->build_path('photos_create')->{path} => 'photos.html';
is $r->build_path('photos_show', id => 456)->{path} => 'photos/456.html';
is $r->build_path('photos_update_form', id => 789)->{path} => 'photos/789/edit.html';
is $r->build_path('photos_update', id => 987)->{path} => 'photos/987.html';
is $r->build_path('photos_delete', id => 654)->{path} => 'photos/654.html';
is $r->build_path('photos_delete_form', id => 222)->{path} => 'photos/222/delete.html';

is $r->build_path('photos_index')->{method} => 'get';
is $r->build_path('photos_create_form')->{method} => 'get';
is $r->build_path('photos_create')->{method} => 'post';
is $r->build_path('photos_show', id => 456)->{method} => 'get';
is $r->build_path('photos_update_form', id => 789)->{method} => 'get';
is $r->build_path('photos_update', id => 987)->{method} => 'put';
is $r->build_path('photos_delete', id => 654)->{method} => 'delete';
is $r->build_path('photos_delete_form', id => 222)->{method} => 'get';



### empty format (explicitly)

$r = Forward::Routes->new->format('');
$r->add_resources('users','photos','tags');

$m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index'};

$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create_form'};

$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'create'};

$m = $r->match(get => 'photos/1');
is_deeply $m->[0]->params => {controller => 'photos', action => 'show', id => 1};

$m = $r->match(get => 'photos/1/edit');
is_deeply $m->[0]->params => {controller => 'photos', action => 'update_form', id => 1};

$m = $r->match(get => 'photos/1/delete');
is_deeply $m->[0]->params => {controller => 'photos', action => 'delete_form', id => 1};

$m = $r->match(put => 'photos/1');
is_deeply $m->[0]->params => {controller => 'photos', action => 'update', id => 1};

$m = $r->match(delete => 'photos/1');
is_deeply $m->[0]->params => {controller => 'photos', action => 'delete', id => 1};

is $r->build_path('photos_index')->{path} => 'photos';
is $r->build_path('photos_create_form')->{path} => 'photos/new';
is $r->build_path('photos_create')->{path} => 'photos';
is $r->build_path('photos_show', id => 456)->{path} => 'photos/456';
is $r->build_path('photos_update_form', id => 789)->{path} => 'photos/789/edit';
is $r->build_path('photos_update', id => 987)->{path} => 'photos/987';
is $r->build_path('photos_delete', id => 654)->{path} => 'photos/654';
is $r->build_path('photos_delete_form', id => 222)->{path} => 'photos/222/delete';


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



### wrong format

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
