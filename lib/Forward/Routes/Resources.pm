package Forward::Routes::Resources;

use strict;
use warnings;

use parent qw/Forward::Routes/;

use Carp;


sub add_singular {
    my $class  = shift;
    my $parent = shift;

    my $names = $_[0] && ref $_[0] eq 'ARRAY' ? [@{$_[0]}] : [@_];

    $names = __PACKAGE__->_prepare_resource_options(@$names);

    my $last_resource;

    for (my $i=0; $i<@$names; $i++) {

        my $ns_name_prefix = '';

        my $name = $names->[$i];

        # options
        next if ref $name;


        # path name
        my $as = $name;
        my $namespace;
        my $format;
        my $format_exists;
        my $namespace_exists;
        my $only;


        # custom resource params
        if ($names->[$i+1] && ref $names->[$i+1] eq 'HASH') {
            my $params = $names->[$i+1];

            $as               = $params->{as}        if $params->{as};
            $format_exists    = 1                    if exists $params->{format};
            $namespace_exists = 1                    if exists $params->{namespace};
            $format           = $params->{format}    if exists $params->{format};
            $namespace        = $params->{namespace} if exists $params->{namespace};
            $only             = $params->{only}      if $params->{only};
        }

        # selected routes
        my %selected = (
            create      => 1,
            show        => 1,
            update      => 1,
            delete      => 1,
            create_form => 1,
            update_form => 1
        );

        # only
        if ($only) {
            %selected = ();
            foreach my $type (@$only) {
                $selected{$type} = 1;
            }
        }

        # custom namespace
        $namespace = $namespace_exists ? $namespace : $parent->namespace;


        # camelize controller name (default)
        my $ctrl = Forward::Routes::Resources->format_resource_controller->($name);


        # final name
        $ns_name_prefix = __PACKAGE__->namespace_to_name($namespace).'_' if $namespace;
        my $final_name = $ns_name_prefix.$name;


        # nested resource name adjustment
        my @parent_names;
        if ($parent->_is_plural_resource) {

            @parent_names = $parent->_parent_resource_names;

            my $parent_name_prefix = join('_', @parent_names).'_';
            $final_name = $parent_name_prefix.$final_name;
        }


        # nested resource members
        # e.g. /magazines/:magazine_id/geocoder (:magazine_id represents the
        # nested resource members)
        $parent = $parent->_nested_resource_members
          if $parent->_is_plural_resource;


        # create resource
        my $resource = $parent->_add_resource_route($as)->_is_singular_resource(1);


        # save resource attributes
        $resource->{_name}      = $name;
        $resource->{_ctrl}      = $ctrl;

        # custom format
        $resource->format($format) if $format_exists;
        $resource->namespace($namespace) if $namespace_exists;


        # members
        $resource->add_route('/new')
          ->via('get')
          ->to("$ctrl#create_form")
          ->name($final_name.'_create_form')
          if $selected{create_form};;

        $resource->add_route('/edit')
          ->via('get')
          ->to("$ctrl#update_form")
          ->name($final_name.'_update_form')
          if $selected{update_form};

        $resource->add_route
          ->via('post')
          ->to("$ctrl#create")
          ->name($final_name.'_create')
          if $selected{create};

        $resource->add_route
          ->via('get')
          ->to("$ctrl#show")
          ->name($final_name.'_show')
          if $selected{show};

        $resource->add_route
          ->via('put')
          ->to("$ctrl#update")
          ->name($final_name.'_update')
          if $selected{update};

        $resource->add_route
          ->via('delete')
          ->to("$ctrl#delete")
          ->name($final_name.'_delete')
          if $selected{delete};

        $last_resource = $resource;
    }

    return $last_resource;
}


sub add_plural {
    my $class  = shift;
    my $parent = shift;

    my $names = $_[0] && ref $_[0] eq 'ARRAY' ? [@{$_[0]}] : [@_];

    $names = __PACKAGE__->_prepare_resource_options(@$names);

    my $last_resource;

    for (my $i=0; $i<@$names; $i++) {

        my $ns_name_prefix = '';

        my $name = $names->[$i];

        # options
        next if ref $name;

        # path name
        my $as = $name;
        my $constraints;
        my $namespace;
        my $format;
        my $format_exists;
        my $namespace_exists;
        my $only;

        # custom resource params
        if ($names->[$i+1] && ref $names->[$i+1] eq 'HASH') {
            my $params = $names->[$i+1];

            $as               = $params->{as}          if $params->{as};
            $constraints      = $params->{constraints} if $params->{constraints};
            $format_exists    = 1                      if exists $params->{format};
            $namespace_exists = 1                      if exists $params->{namespace};
            $format           = $params->{format}      if exists $params->{format};
            $namespace        = $params->{namespace}   if exists $params->{namespace};
            $only             = $params->{only}        if $params->{only};
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


        # final name
        $ns_name_prefix = __PACKAGE__->namespace_to_name($namespace).'_' if $namespace;
        my $final_name = $ns_name_prefix.$name;


        # nested resource name adjustment
        my @parent_names;
        if ($parent->_is_plural_resource) {
            @parent_names = $parent->_parent_resource_names;

            my $parent_name_prefix = join('_', @parent_names).'_';
            $final_name = $parent_name_prefix.$final_name;
        }
        push @parent_names, $ns_name_prefix.$name;


        # nested resource members
        # e.g. /magazines/:magazine_id/ads/:id (:magazine_id represents the
        # nested resource members)
        $parent = $parent->_nested_resource_members
          if $parent->_is_plural_resource;


        # create resource
        my $resource = $parent->_add_resource_route($as)
          ->_is_plural_resource(1)
          ->_parent_resource_names(@parent_names);


        # save resource attributes
        $resource->{_name}          = $name;
        $resource->{_ctrl}          = $ctrl;
        $resource->{_id_constraint} = $id_constraint;

        # custom format
        $resource->format($format) if $format_exists;
        $resource->namespace($namespace) if $namespace_exists;


        # collection
        my $collection = $resource->_collection
          if $selected{index} || $selected{create} || $selected{create_form};

        $collection->add_route
          ->via('get')
          ->to($ctrl."#index")
          ->name($final_name.'_index')
          if $selected{index};

        $collection->add_route
          ->via('post')
          ->to($ctrl."#create")
          ->name($final_name.'_create')
          if $selected{create};

        # new resource item
        $collection->add_route('/new')
          ->via('get')
          ->to($ctrl."#create_form")
          ->name($final_name.'_create_form')
          if $selected{create_form};


        # members
        my $members = $resource->_members if $selected{show} || $selected{update}
          || $selected{delete} || $selected{update_form}
          || $selected{delete_form};

        $members->add_route
          ->via('get')
          ->to($ctrl."#show")
          ->name($final_name.'_show')
          if $selected{show};

        $members->add_route
          ->via('put')
          ->to($ctrl."#update")
          ->name($final_name.'_update')
          if $selected{update};

        $members->add_route
          ->via('delete')
          ->to($ctrl."#delete")
          ->name($final_name.'_delete')
          if $selected{delete};

        $members->add_route('edit')
          ->via('get')
          ->to($ctrl."#update_form")
          ->name($final_name.'_update_form')
          if $selected{update_form};

        $members->add_route('delete')
          ->via('get')
          ->to($ctrl."#delete_form")
          ->name($final_name.'_delete_form')
          if $selected{delete_form};

        $last_resource = $resource;
    }

    return $last_resource;
}


sub _nested_resource_members {
    my $self = shift;

    my $parent_name = ($self->_parent_resource_names)[-1];

    my $parent_id_name = $self->singularize->($parent_name).'_id';

    return $self->add_route(':'.$parent_id_name)
      ->constraints($parent_id_name => $self->{_id_constraint});
}


sub add_member_route {
    my $self = shift;
    my (@params) = @_;

    my $child = Forward::Routes->new(@params);

    my $members = $self->_is_plural_resource ? $self->_members : $self;

    # makes sure that inheritance works
    $members->_add_child($child);

    # name
    my $name = $params[0];
    $name =~s|^/||;
    $name =~s|/|_|g;


    # custom namespace
    my $namespace = $self->namespace;

    my $ns_name_prefix = $namespace ? __PACKAGE__->namespace_to_name($namespace).'_' : '';


    # Auto set controller and action params and name
    $child->to($self->{_ctrl}.'#'.$name);
    $child->name($ns_name_prefix.$self->{_name}.'_'.$name);

    return $child;

}


sub _members {
    my $self = shift;

    my $id_constraint = $self->{_id_constraint} || die 'missing id constraint';

    $self->{_members} ||= $self->add_route(':id')
      ->constraints('id' => $id_constraint);

    $self->{_members}->pattern->{exclude}->{id} ||= [];
    push @{$self->{_members}->pattern->{exclude}->{id}}, 'new';

    return $self->{_members};
}


sub add_collection_route {
    my $self = shift;
    my (@params) = @_;

    $self->_is_plural_resource || Carp::croak('add_collection_route can only be called on plural resources');

    my $child = Forward::Routes->new(@params);

    # makes sure that inheritance works
    $self->_collection->_add_child($child);

    # name
    my $name = $params[0];
    $name =~s|^/||;
    $name =~s|/|_|g;


    $self->{_members}->pattern->{exclude}->{id} ||= [];
    push @{$self->{_members}->pattern->{exclude}->{id}}, $name;


    # custom namespace
    my $namespace = $self->namespace;

    my $ns_name_prefix = $namespace ? __PACKAGE__->namespace_to_name($namespace).'_' : '';


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


sub _parent_resource_names {
    my $self = shift;
    my (@names) = @_;

    # Initialize
    $self->{_parent_resource_names} ||=[];


    if (@names) {
        $self->{_parent_resource_names} = \@names;
        return $self;
    }

    return @{$self->{_parent_resource_names}};
}


sub _prepare_resource_options {
    my $self = shift;
    my (@names) = @_;

    my @final;
    while (@names) {
        my $name = shift(@names);

        if ($name =~m/^-/){
            $name =~s/^-//;
            push @final, {} unless ref $final[-1] eq 'HASH';
            $final[-1]->{$name} = shift(@names);
        }
        else {
            push @final, $name;
        }
    }
    return \@final;
}


sub namespace_to_name {
    my $self = shift;
    my ($namespace) = @_;

    my @new_parts;

    my @parts = split /::/, $namespace;

    for my $part (@parts) {
        my @words;
        while ($part =~ s/([A-Z]{1}[^A-Z]*)//){
            my $word = lc $1;
            push @words, $word;
        }
        push @new_parts, join '_', @words;
    }
    return join '_', @new_parts;

}

1;
