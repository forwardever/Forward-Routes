#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use Forward::Routes;



#############################################################################
### nested resources and namespaces

# magazine routes
my $r = Forward::Routes->new;
my $ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager');

my $m = $r->match(get => 'magazines');
is $m->[0]->name, 'admin_magazines_index';

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines_manager_create_form';



# nested routes also has namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager' => -namespace => 'Admin');

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines_admin_manager_create_form';



# controller namespace organized exactly as resource nesting
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_singular_resources('manager' => -namespace => 'Admin::Magazines');

$m = $r->match(get => 'magazines/4/manager/new');
is $m->[0]->name, 'admin_magazines_admin_magazines_manager_create_form';

