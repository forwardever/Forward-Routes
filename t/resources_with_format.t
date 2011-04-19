#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 8;


#############################################################################
### nested routes with format

# no format requirement (defaults to format ''), but format passed

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
