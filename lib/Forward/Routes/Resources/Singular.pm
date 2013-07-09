package Forward::Routes::Resources::Singular;
use strict;
use warnings;
use parent qw/Forward::Routes::Resources/;


sub _add {
    my $self = shift;
    my ($parent, $name, $options) = @_;

    my $ns_name_prefix = '';

    # path name
    my $as = $name;
    my $namespace;
    my $format;
    my $format_exists;
    my $namespace_exists;
    my $only;


    # custom resource params
    if ($options) {
        $as               = $options->{as}        if $options->{as};
        $format_exists    = 1                     if exists $options->{format};
        $namespace_exists = 1                     if exists $options->{namespace};
        $format           = $options->{format}    if exists $options->{format};
        $namespace        = $options->{namespace} if exists $options->{namespace};
        $only             = $options->{only}      if $options->{only};
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
    $ns_name_prefix = Forward::Routes::Resources->namespace_to_name($namespace).'_' if $namespace;
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
    my $resource = Forward::Routes::Resources->new($as);
    $resource->_is_singular_resource(1);
    $parent->_add_child($resource);


    # save resource attributes
    $resource->_name($name);
    $resource->_ctrl($ctrl);

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

    return $resource;
}

1;
