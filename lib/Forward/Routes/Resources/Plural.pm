package Forward::Routes::Resources::Plural;
use strict;
use warnings;
use parent qw/Forward::Routes::Resources/;


sub _add {
    my $self = shift;
    my ($parent, $resource_name, $options) = @_;

    my $resource = Forward::Routes::Resources::Plural->new($resource_name);

    # nested resource members
    # e.g. /magazines/:magazine_id/ads/:id (:magazine_id represents the
    # nested resource members)
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


    # create resource
    $resource->_is_plural_resource(1)->name($route_name);
    $resource->{resource_name_part} = $ns_name_prefix . $resource_name;


    # save resource attributes
    $resource->resource_name($resource_name);
    $resource->_ctrl($ctrl);


    # collection
    my $collection = $resource->_collection
      if $enabled_routes->{index} || $enabled_routes->{create} || $enabled_routes->{create_form};

    $collection->add_route
      ->via('get')
      ->to($ctrl."#index")
      ->name($route_name.'_index')
      if $enabled_routes->{index};

    $collection->add_route
      ->via('post')
      ->to($ctrl."#create")
      ->name($route_name.'_create')
      if $enabled_routes->{create};

    # new resource item
    $collection->add_route('/new')
      ->via('get')
      ->to($ctrl."#create_form")
      ->name($route_name.'_create_form')
      if $enabled_routes->{create_form};


    # members
    my $members = $resource->init_members if $enabled_routes->{show} || $enabled_routes->{update}
      || $enabled_routes->{delete} || $enabled_routes->{update_form}
      || $enabled_routes->{delete_form};

    $members->add_route
      ->via('get')
      ->to($ctrl."#show")
      ->name($route_name.'_show')
      if $enabled_routes->{show};

    $members->add_route
      ->via('put')
      ->to($ctrl."#update")
      ->name($route_name.'_update')
      if $enabled_routes->{update};

    $members->add_route
      ->via('delete')
      ->to($ctrl."#delete")
      ->name($route_name.'_delete')
      if $enabled_routes->{delete};

    $members->add_route('edit')
      ->via('get')
      ->to($ctrl."#update_form")
      ->name($route_name.'_update_form')
      if $enabled_routes->{update_form};

    $members->add_route('delete')
      ->via('get')
      ->to($ctrl."#delete_form")
      ->name($route_name.'_delete_form')
      if $enabled_routes->{delete_form};

    return $resource;
}


sub add_collection_route {
    my $self = shift;
    my ($pattern, @params) = @_;

    my $child = Forward::Routes->new($pattern, @params);
    $self->_collection->_add_child($child);

    # name
    my $collection_route_name = $pattern;
    $collection_route_name =~s|^/||;
    $collection_route_name =~s|/|_|g;

    $self->{_members}->pattern->{exclude}->{id} ||= [];
    push @{$self->{_members}->pattern->{exclude}->{id}}, $collection_route_name;


    # Auto set controller and action params and name
    $child->to($self->{_ctrl}  . '#' . $collection_route_name);
    $child->name($self->{name} . '_' . $collection_route_name);

    return $child;
}


sub _collection {
    my $self = shift;

    $self->{_collection} ||= $self->add_route;

    return $self->{_collection};
}


sub init_members {
    my $self = shift;

    return $self->{_members} if $self->{_members};

    my $id_constraint = $self->{id_constraint} || die 'missing id constraint';

    $self->{_members} = $self->add_route(':id')
      ->constraints('id' => $id_constraint);

    $self->{_members}->pattern->{exclude}->{id} ||= [];
    push @{$self->{_members}->pattern->{exclude}->{id}}, 'new';

    return $self->{_members};
}


sub _members {
    my $self = shift;
    return $self->{_members};
}


sub _nested_resource_members {
    my $self = shift;

    my $parent_name = $self->{resource_name_part};

    my $parent_id_name = $self->singularize->($parent_name).'_id';

    return $self->add_route(':'.$parent_id_name)
      ->constraints($parent_id_name => $self->{id_constraint});
}


sub id_constraint {
    my $self = shift;
    my (@params) = @_;

    return $self->{id_constraint} unless @params;

    $self->{id_constraint} = $params[0];

    return $self;
}


sub enabled_routes {
    my $self = shift;

    my $only = $self->{only};

    my %selected = (
        index       => 1,
        create      => 1,
        show        => 1,
        update      => 1,
        delete      => 1,
        create_form => 1,
        update_form => 1,
        delete_form => 1
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
