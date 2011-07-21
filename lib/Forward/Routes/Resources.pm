package Forward::Routes::Resources;

use strict;
use warnings;

use parent qw/Forward::Routes/;


sub add_singular {
    my $class  = shift;
    my $parent = shift;

    my $names = $_[0] && ref $_[0] eq 'ARRAY' ? [@{$_[0]}] : [@_];

    $names = __PACKAGE__->_prepare_resource_options(@$names);

    my $last_resource;
    my $ns_name_prefix = '';
    my $ns_ctrl_prefix = '';


    for (my $i=0; $i<@$names; $i++) {

        my $name = $names->[$i];

        # options
        next if ref $name;


        # path name
        my $as = $name;
        my $namespace;
        my $format;
        my $format_exists;
        my $only;


        # custom resource params
        if ($names->[$i+1] && ref $names->[$i+1] eq 'HASH') {
            my $params = $names->[$i+1];

            $as            = $params->{as}        if $params->{as};
            $namespace     = $params->{namespace} if $params->{namespace};
            $format_exists = 1                    if exists $params->{format};
            $format        = $params->{format}    if exists $params->{format};
            $only          = $params->{only}      if $params->{only};
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
        $ns_ctrl_prefix = $namespace.'::' if $namespace;


        # camelize controller name (default)
        my $ctrl = Forward::Routes::Resources->format_resource_controller->($name);

        $ns_name_prefix = __PACKAGE__->namespace_to_name($namespace).'_' if $namespace;

        # Nested resources
        my $resource;
        my $parent_name_prefix = '';
        if ($parent->_is_plural_resource) {

            my @parent_names = $parent->_parent_resource_names;

            $parent_name_prefix = join('_', @parent_names).'_';

            my $parent_id_name = $parent->singularize->($parent_names[-1]).'_id';

            $resource = $parent->_add_resource_route(':'.$parent_id_name.'/'.$as)
              ->constraints($parent_id_name => qr/[^.\/]+/);
        }
        else {
            $resource = $parent->_add_resource_route($as);
        }


        # custom format
        $resource->format($format) if $format_exists;
    

        $resource->add_route('/new')
          ->via('get')
          ->to($ns_ctrl_prefix."$ctrl#create_form")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_create_form')
          if $selected{create_form};;
    
        $resource->add_route('/edit')
          ->via('get')
          ->to($ns_ctrl_prefix."$ctrl#update_form")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_update_form')
          if $selected{update_form};

        $resource->add_route
          ->via('post')
          ->to($ns_ctrl_prefix."$ctrl#create")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_create')
          if $selected{create};
    
        $resource->add_route
          ->via('get')
          ->to($ns_ctrl_prefix."$ctrl#show")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_show')
          if $selected{show};
    
        $resource->add_route
          ->via('put')
          ->to($ns_ctrl_prefix."$ctrl#update")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_update')
          if $selected{update};
    
        $resource->add_route
          ->via('delete')
          ->to($ns_ctrl_prefix."$ctrl#delete")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_delete')
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
    my $ns_name_prefix = '';
    my $ns_ctrl_prefix = '';


    for (my $i=0; $i<@$names; $i++) {

        my $name = $names->[$i];

        # options
        next if ref $name;

        # path name
        my $as = $name;
        my $constraints;
        my $namespace;
        my $format;
        my $format_exists;
        my $only;

        # custom resource params
        if ($names->[$i+1] && ref $names->[$i+1] eq 'HASH') {
            my $params = $names->[$i+1];

            $as            = $params->{as}          if $params->{as};
            $constraints   = $params->{constraints} if $params->{constraints};
            $namespace     = $params->{namespace}   if $params->{namespace};
            $format_exists = 1                      if exists $params->{format};
            $format        = $params->{format}      if exists $params->{format};
            $only          = $params->{only}        if $params->{only};
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
        my $id_constraint = $constraints->{id} || qr/(?!new\Z)[^.\/]+/;


        # custom namespace
        $ns_ctrl_prefix = $namespace.'::' if $namespace;


        # camelize controller name (default)
        my $ctrl = Forward::Routes::Resources->format_resource_controller->($name);

        $ns_name_prefix = __PACKAGE__->namespace_to_name($namespace).'_' if $namespace;

        # Nested resources
        my $resource;
        my $parent_name_prefix = '';
        if ($parent->_is_plural_resource) {
            my @parent_names = $parent->_parent_resource_names;

            $parent_name_prefix = join('_', @parent_names).'_';

            my $parent_id_name = $parent->singularize->($parent_names[-1]).'_id';

            $resource = $parent->_add_resource_route(':'.$parent_id_name.'/'.$as)
              ->_is_plural_resource(1)
              ->_parent_resource_names($parent->_parent_resource_names, $ns_name_prefix.$name)
              ->constraints($parent_id_name => qr/[^.\/]+/);
        }
        else {
            $resource = $parent->_add_resource_route($as)
              ->_is_plural_resource(1)
              ->_parent_resource_names($ns_name_prefix.$name);
        }


        # custom format
        $resource->format($format) if $format_exists;


        # resource
        $resource->add_route
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#index")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_index')
          if $selected{index};

        $resource->add_route
          ->via('post')
          ->to($ns_ctrl_prefix.$ctrl."#create")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_create')
          if $selected{create};

        # new resource item
        $resource->add_route('/new')
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#create_form")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_create_form')
          if $selected{create_form};

        # modify resource item
        my $nested = $resource->add_route(':id')
          ->constraints('id' => $id_constraint)
          if $selected{show} || $selected{update} || $selected{delete}
            || $selected{update_form} || $selected{delete_form};

        # save members in $resource
        $resource->{_members} = $nested;

        $nested->add_route
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#show")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_show')
          if $selected{show};

        $nested->add_route
          ->via('put')
          ->to($ns_ctrl_prefix.$ctrl."#update")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_update')
          if $selected{update};

        $nested->add_route
          ->via('delete')
          ->to($ns_ctrl_prefix.$ctrl."#delete")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_delete')
          if $selected{delete};

        $nested->add_route('edit')
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#update_form")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_update_form')
          if $selected{update_form};

        $nested->add_route('delete')
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#delete_form")
          ->name($parent_name_prefix.$ns_name_prefix.$name.'_delete_form')
          if $selected{delete_form};

        $last_resource = $resource;
    }

    return $last_resource;
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
    my $self    = shift;
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
