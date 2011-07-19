#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 4;


#############################################################################
### namespace_to_name method

my $r = Forward::Routes->new;

is $r->namespace_to_name('Admin'), 'admin';
is $r->namespace_to_name('Admin::Users'), 'admin_users';
is $r->namespace_to_name('NewAdmin'), 'new_admin';
is $r->namespace_to_name('NewAdmin::OldUser'), 'new_admin_old_user';

# TO DO: CORRECT ?
# is $r->namespace_to_name('NEWAdmin::OldUser'), 'n_e_w_admin_old_user';
