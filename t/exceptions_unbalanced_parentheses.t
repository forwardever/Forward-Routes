#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 3;


#############################################################################
### exceptions: unbalanced parentheses

# Open
my $r = Forward::Routes->new;
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

