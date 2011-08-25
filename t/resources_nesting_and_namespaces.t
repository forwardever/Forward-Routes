#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use Forward::Routes;



#############################################################################
### nested resources and namespaces

# magazine routes
my $r = Forward::Routes->new;
my $ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads' => -namespace => undef);

my $m = $r->match(get => 'magazines');
is $m->[0]->name, 'admin_magazines_index';
is $m->[0]->controller_class, 'Admin::Magazines';


$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_ads_create_form';
is $m->[0]->controller_class, 'Ads';



# nested routes inherit namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads');

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_admin_ads_create_form';
is $m->[0]->controller_class, 'Admin::Ads';



# nested routes also has namespace
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads' => -namespace => 'Admin');

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_admin_ads_create_form';
is $m->[0]->controller_class, 'Admin::Ads';


# controller namespace organized exactly as resource nesting
$r = Forward::Routes->new;
$ads = $r->add_resources('magazines' => -namespace => 'Admin')
  ->add_resources('ads' => -namespace => 'Admin::Magazines');

$m = $r->match(get => 'magazines/4/ads/new');
is $m->[0]->name, 'admin_magazines_admin_magazines_ads_create_form';
is $m->[0]->controller_class, 'Admin::Magazines::Ads';
