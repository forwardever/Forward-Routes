package Forward::Routes::Resources::Plural;
use strict;
use warnings;
use parent qw/Forward::Routes::Resources/;


sub _add {
    my $self = shift;
    my ($parent, $name, $options) = @_;

    # path name
    my $as = $name;
    my $constraints;
    my $namespace;
    my $format;
    my $format_exists;
    my $namespace_exists;
    my $only;

    # custom resource params
    if ($options) {
        $as               = $options->{as}          if $options->{as};
        $constraints      = $options->{constraints} if $options->{constraints};
        $format_exists    = 1                       if exists $options->{format};
        $namespace_exists = 1                       if exists $options->{namespace};
        $format           = $options->{format}      if exists $options->{format};
        $namespace        = $options->{namespace}   if exists $options->{namespace};
        $only             = $options->{only}        if $options->{only};
    }

    # selected routes
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

    # only
    if ($only) {
        %selected = ();
        foreach my $type (@$only) {
            $selected{$type} = 1;
        }
    }

    # custom constraint
    my $id_constraint = $constraints->{id} || qr/[^.\/]+/;


    # custom namespace
    $namespace = $namespace_exists ? $namespace : $parent->namespace;


    # camelize controller name (default)
    my $ctrl = Forward::Routes::Resources->format_resource_controller->($name);


    # resource name
    # nested resource name adjustment
    my $parent_resource_name = '';
    if ($parent->_is_plural_resource) {
        $parent_resource_name = defined $parent->resource_name ? $parent->resource_name . '_' : '';
    }
    my $ns_name_prefix = $namespace ? Forward::Routes::Resources->namespace_to_name($namespace) . '_' : '';
    my $resource_name = $parent_resource_name . $ns_name_prefix . $name;



    # nested resource members
    # e.g. /magazines/:magazine_id/ads/:id (:magazine_id represents the
    # nested resource members)
    $parent = $parent->_nested_resource_members
      if $parent->_is_plural_resource;


    # create resource
    my $resource = Forward::Routes::Resources::Plural->new($as);
    $resource->_is_plural_resource(1)->resource_name($resource_name);
    $parent->_add_child($resource);

    $resource->{resource_name_part} = $ns_name_prefix . $name;


    # save resource attributes
    $resource->_name($name);
    $resource->_ctrl($ctrl);
    $resource->_id_constraint($id_constraint);

    # custom format
    $resource->format($format) if $format_exists;
    $resource->namespace($namespace) if $namespace_exists;


    # collection
    my $collection = $resource->_collection
      if $selected{index} || $selected{create} || $selected{create_form};

    $collection->add_route
      ->via('get')
      ->to($ctrl."#index")
      ->name($resource_name.'_index')
      if $selected{index};

    $collection->add_route
      ->via('post')
      ->to($ctrl."#create")
      ->name($resource_name.'_create')
      if $selected{create};

    # new resource item
    $collection->add_route('/new')
      ->via('get')
      ->to($ctrl."#create_form")
      ->name($resource_name.'_create_form')
      if $selected{create_form};


    # members
    my $members = $resource->init_members if $selected{show} || $selected{update}
      || $selected{delete} || $selected{update_form}
      || $selected{delete_form};

    $members->add_route
      ->via('get')
      ->to($ctrl."#show")
      ->name($resource_name.'_show')
      if $selected{show};

    $members->add_route
      ->via('put')
      ->to($ctrl."#update")
      ->name($resource_name.'_update')
      if $selected{update};

    $members->add_route
      ->via('delete')
      ->to($ctrl."#delete")
      ->name($resource_name.'_delete')
      if $selected{delete};

    $members->add_route('edit')
      ->via('get')
      ->to($ctrl."#update_form")
      ->name($resource_name.'_update_form')
      if $selected{update_form};

    $members->add_route('delete')
      ->via('get')
      ->to($ctrl."#delete_form")
      ->name($resource_name.'_delete_form')
      if $selected{delete_form};

    return $resource;

}


sub add_collection_route {
    my $self = shift;
    my (@params) = @_;

    my $child = Forward::Routes->new(@params);
    $self->_collection->_add_child($child);


    # name
    my $name = $params[0];
    $name =~s|^/||;
    $name =~s|/|_|g;

    my $namespace = $self->namespace;
    my $ns_name_prefix = $namespace ? Forward::Routes::Resources->namespace_to_name($namespace) . '_' : '';


    $self->{_members}->pattern->{exclude}->{id} ||= [];
    push @{$self->{_members}->pattern->{exclude}->{id}}, $name;



    # Auto set controller and action params and name
    $child->to($self->{_ctrl}.'#'.$name);
    $child->name($ns_name_prefix.$self->{_name}.'_'.$name);

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

    my $id_constraint = $self->{_id_constraint} || die 'missing id constraint';

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
      ->constraints($parent_id_name => $self->{_id_constraint});
}


sub _id_constraint {
    my $self = shift;
    my (@params) = @_;

    return $self->{_id_constraint} unless @params;

    $self->{_id_constraint} = $params[0];

    return $self;
}


1;
