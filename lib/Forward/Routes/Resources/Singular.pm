package Forward::Routes::Resources::Singular;
use strict;
use warnings;
use parent qw/Forward::Routes::Resources/;


sub _add {
    my $self = shift;
    my ($parent, $resource_name, $options) = @_;

    my $resource = Forward::Routes::Resources::Singular->new($resource_name,
        _is_singular_resource => 1
    );

    if ($parent->_is_plural_resource) {
        my $new_parent = $parent->_nested_resource_members;
        $new_parent->_add_child($resource);
    }
    else {
        $parent->_add_child($resource);
    }

    # after _add_child because of inheritance
    $resource->init_options($options);


    # enabled routes
    my $enabled_routes = $resource->enabled_routes;


    # camelize controller name (default)
    my $ctrl = Forward::Routes::Resources->format_resource_controller->($resource_name);


    # resource name
    # nested resource name adjustment
    my $parent_resource_name = '';
    if ($parent->_is_plural_resource) {
        $parent_resource_name = defined $parent->name ? $parent->name . '_' : '';
    }
    my $ns_name_prefix = $resource->namespace ? Forward::Routes::Resources->namespace_to_name($resource->namespace) . '_' : '';
    my $route_name = $parent_resource_name . $ns_name_prefix . $resource_name;
    $resource->name($route_name);;


    # save resource attributes
    $resource->resource_name($resource_name);
    $resource->_ctrl($ctrl);


    # members
    $resource->add_route('/new')
      ->via('get')
      ->to("$ctrl#create_form")
      ->name($route_name.'_create_form')
      if $enabled_routes->{create_form};;

    $resource->add_route('/edit')
      ->via('get')
      ->to("$ctrl#update_form")
      ->name($route_name.'_update_form')
      if $enabled_routes->{update_form};

    $resource->add_route
      ->via('post')
      ->to("$ctrl#create")
      ->name($route_name.'_create')
      if $enabled_routes->{create};

    $resource->add_route
      ->via('get')
      ->to("$ctrl#show")
      ->name($route_name.'_show')
      if $enabled_routes->{show};

    $resource->add_route
      ->via('put')
      ->to("$ctrl#update")
      ->name($route_name.'_update')
      if $enabled_routes->{update};

    $resource->add_route
      ->via('delete')
      ->to("$ctrl#delete")
      ->name($route_name.'_delete')
      if $enabled_routes->{delete};

    return $resource;
}


sub enabled_routes {
    my $self = shift;

    my $only = $self->{only};

    my %selected = (
        create      => 1,
        show        => 1,
        update      => 1,
        delete      => 1,
        create_form => 1,
        update_form => 1
    );

    if ($self->{only}) {
        %selected = ();
        foreach my $type (@$only) {
            $selected{$type} = 1;
        }
    }

    return \%selected;
}


1;
