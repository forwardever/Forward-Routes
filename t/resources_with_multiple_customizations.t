#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 3;


#############################################################################
### resources with multiple customizations


my $r = Forward::Routes->new;
$r->add_resources(
    'users',
    'photos' => -constraints => {id => qr/\d{6}/}, -as => 'pictures',
      -namespace => 'Admin',
    'tags'
);

my $m = $r->match(get => '/pictures/123456');
is_deeply $m->[0]->params => {controller => 'Admin::Photos', action => 'show', id => 123456};

is $r->build_path('admin_photos_show', id => 123456)->{path} => 'pictures/123456';

# constraint works
$m = $r->match(get => '/pictures/123');
is $m, undef;

