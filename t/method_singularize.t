#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 4;


#############################################################################
### to method

my $r = Forward::Routes->new;

# default singularize
is $r->singularize->('users'), 'user';
is $r->singularize->('queries'), 'query';

# overwrite singularize
my $code_ref = sub {return shift;};
$r->singularize($code_ref);

is $r->singularize, $code_ref;
is $r->singularize->('users'), 'users';

