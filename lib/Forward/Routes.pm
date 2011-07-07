package Forward::Routes;

use strict;
use warnings;

use Forward::Routes::Match;
use Forward::Routes::Pattern;
use Scalar::Util qw/weaken/;
use Carp 'croak';

our $VERSION = '0.22';

sub new {
    my $class = shift;

    $class = ref $class if ref $class;

    my $self = bless {}, $class;

    # Pattern
    my $pattern = @_ % 2 ? shift : undef;
    $self->pattern->pattern($pattern) if defined $pattern;

    # Shortcut in case of chained API
    return $self unless @_;

    # Process remaining params
    return $self->initialize(@_);
}


sub initialize {
    my $self = shift;

    # Remaining params
    my $params = ref $_[0] eq 'HASH' ? {%{$_[0]}} : {@_};

    # Save to route
    $self->method(delete $params->{method});
    $self->method(delete $params->{via});
    $self->defaults(delete $params->{defaults});
    $self->name(delete $params->{name});
    $self->to(delete $params->{to});
    $self->_is_plural_resource(delete $params->{_is_plural_resource});
    $self->constraints(delete $params->{constraints});

    return $self;

}


sub add_route {
    my $self = shift;

    my $child = $self->new(@_);

    # Format inheritance
    $child->format([@{$self->{format}}]) if $self->{format};
    $child->method([@{$self->{method}}]) if $self->{method};

    push @{$self->children}, $child;

    $child->parent($self);

    return $child;
}


sub bridge {
    my $self = shift;

    return $self->add_route(@_)->_is_bridge(1);
}


sub _is_bridge {
    my $self = shift;

    return $self->{_is_bridge} unless defined $_[0];

    $self->{_is_bridge} = $_[0];

    return $self;
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


sub add_singular_resources {
    my $self = shift;

    my $names = $_[0] && ref $_[0] eq 'ARRAY' ? [@{$_[0]}] : [@_];

    $names = $self->_prepare_resource_options(@$names);

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
        $ns_ctrl_prefix   = $self->format_resource_controller->($namespace).'::' if $namespace;
        $ns_name_prefix   = $namespace.'_' if $namespace;


        # camelize controller name (default)
        my $ctrl = $self->format_resource_controller->($name);
    

        my $resource = $self->add_route($as);

        # custom format
        $resource->format($format) if $format_exists;
    
        $resource->add_route('/new')
          ->via('get')
          ->to($ns_ctrl_prefix."$ctrl#create_form")
          ->name($ns_name_prefix.$name.'_create_form')
          if $selected{create_form};;
    
        $resource->add_route('/edit')
          ->via('get')
          ->to($ns_ctrl_prefix."$ctrl#update_form")
          ->name($ns_name_prefix.$name.'_update_form')
          if $selected{update_form};

        $resource->add_route
          ->via('post')
          ->to($ns_ctrl_prefix."$ctrl#create")
          ->name($ns_name_prefix.$name.'_create')
          if $selected{create};
    
        $resource->add_route
          ->via('get')
          ->to($ns_ctrl_prefix."$ctrl#show")
          ->name($ns_name_prefix.$name.'_show')
          if $selected{show};
    
        $resource->add_route
          ->via('put')
          ->to($ns_ctrl_prefix."$ctrl#update")
          ->name($ns_name_prefix.$name.'_update')
          if $selected{update};
    
        $resource->add_route
          ->via('delete')
          ->to($ns_ctrl_prefix."$ctrl#delete")
          ->name($ns_name_prefix.$name.'_delete')
          if $selected{delete};

        $last_resource = $resource;
    }

    return $last_resource;
}


sub add_resources {
    my $self = shift;

    my $names = $_[0] && ref $_[0] eq 'ARRAY' ? [@{$_[0]}] : [@_];

    $names = $self->_prepare_resource_options(@$names);

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
        $ns_ctrl_prefix   = $self->format_resource_controller->($namespace).'::' if $namespace;
        $ns_name_prefix   = $namespace.'_' if $namespace;


        # camelize controller name (default)
        my $ctrl = $self->format_resource_controller->($name);


        # Nested resources
        my $resource;
        my $parent_name_prefix = '';
        if ($self->_is_plural_resource) {

            my @parent_names = $self->_parent_resource_names;

            $parent_name_prefix = join('_', @parent_names).'_';

            my $parent_id_name = $self->singularize->($parent_names[-1]).'_id';

            $resource = $self->add_route(':'.$parent_id_name.'/'.$as)
              ->_is_plural_resource(1)
              ->_parent_resource_names($self->_parent_resource_names, $name)
              ->constraints($parent_id_name => qr/[^.\/]+/);
        }
        else {
            $resource = $self->add_route($as)
              ->_is_plural_resource(1)
              ->_parent_resource_names($name);
        }

        # custom format
        $resource->format($format) if $format_exists;


        # resource
        $resource->add_route
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#index")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_index')
          if $selected{index};

        $resource->add_route
          ->via('post')
          ->to($ns_ctrl_prefix.$ctrl."#create")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_create')
          if $selected{create};

        # new resource item
        $resource->add_route('/new')
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#create_form")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_create_form')
          if $selected{create_form};

        # modify resource item
        my $nested = $resource->add_route(':id')
          ->constraints('id' => $id_constraint)
          if $selected{show} || $selected{update} || $selected{delete}
            || $selected{update_form} || $selected{delete_form};

        $nested->add_route
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#show")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_show')
          if $selected{show};

        $nested->add_route
          ->via('put')
          ->to($ns_ctrl_prefix.$ctrl."#update")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_update')
          if $selected{update};

        $nested->add_route
          ->via('delete')
          ->to($ns_ctrl_prefix.$ctrl."#delete")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_delete')
          if $selected{delete};

        $nested->add_route('edit')
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#update_form")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_update_form')
          if $selected{update_form};

        $nested->add_route('delete')
          ->via('get')
          ->to($ns_ctrl_prefix.$ctrl."#delete_form")
          ->name($ns_name_prefix.$parent_name_prefix.$name.'_delete_form')
          if $selected{delete_form};

        $last_resource = $resource;
    }

    return $last_resource;
}


# overwrite code ref for more advanced approach:
# sub {
#     require Lingua::EN::Inflect::Number;
#     return &Lingua::EN::Inflect::Number::to_S($value);
# }
sub singularize {
    my $self = shift;
    my ($code_ref) = @_;

    # Initialize very basic singularize code ref
    $Forward::Routes::singularize ||= sub {
        my $value = shift;

        if ($value =~ s/ies$//) {
            $value .= 'y';
        }
        else {
            $value =~ s/s$//;
        }

        return $value;
    };

    return $Forward::Routes::singularize unless $code_ref;

    $Forward::Routes::singularize = $code_ref;

    return $self;

}


sub format_resource_controller {
    my $self = shift;
    my ($code_ref) = @_;

    $Forward::Routes::format_controller ||= sub {
        my $value = shift;

        my @parts = split /-/, $value;
        for my $part (@parts) {
            $part = join '', map {ucfirst} split /_/, $part;
        }
        return join '::', @parts;
    };

    return $Forward::Routes::format_controller unless $code_ref;

    $Forward::Routes::format_controller = $code_ref;

    return $self;
}


sub defaults {
    my $self = shift;
    my (@params) = @_;

    # Initialize
    my $d = $self->{defaults} ||= {};

    # Getter
    return $d unless defined $params[0];

    # Hash ref or array?
    my $passed_defaults = ref $params[0] eq 'HASH' ? $params[0] : {@params};

    # Merge defaults
    %$d = (%$d, %$passed_defaults);

    return $self;
}


sub name {
    my ($self, $name) = @_;

    return $self->{name} unless defined $name;

    $self->{name} = $name;

    return $self;
}


sub to {
    my $self = shift;
    my ($to) = @_;

    return unless $to;

    my $params;
    @$params{qw/controller action/} = split '#' => $to;

    $params->{controller} ||= undef;

    return $self->defaults($params);
}


sub find_route {
    my ($self, $name) = @_;

    $self->{routes_by_name} ||= {};
    return $self->{routes_by_name}->{$name} if $self->{routes_by_name}->{$name};

    return $self if $self->name && $self->name eq $name;

    foreach my $child (@{$self->children}) {
        my $match = $child->find_route($name, @_);
        $self->{routes_by_name}->{$name} = $match if $match;
        return $match if $match;
    }

    return undef;
}


sub match {
    my ($self, $method, $path) = @_;

    length $method || croak 'Forward::Routes->match: missing request method';
    defined $path || croak 'Forward::Routes->match: missing path';

    # Leading slash
    $path = "/$path" unless $path =~ m{ \A / }x;

    # Search for match
    my $matches = $self->_match(lc($method) => $path);
    return unless $matches;

    return $matches;
}


sub method {
    my $self = shift;

    return $self->{method} unless $_[0];

    my $methods = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    @$methods = map {lc $_} @$methods;

    $self->{method} = $methods;

    return $self;
}


sub via {
    shift->method(@_);
}


sub _match {
    my ($self, $method, $path) = @_;

    # Format
    my $request_format;
    if (!@{$self->children} && $self->{format}) {
        $path =~m/\.([\a-zA-Z0-9]{1,4})$/;
        $request_format = defined $1 ? $1 : '';

        # format extension is only replaced if format constraint exists
        $path =~s/\.[\a-zA-Z0-9]{1,4}$// if $request_format;
    }

    # Current pattern match
    my $captures = [];
    if (defined $self->pattern->pattern) {
        $captures = $self->_match_current_pattern(\$path) || return;
    }

    # No Match, as path not empty, but further children
    return if length($path) && !@{$self->children};

    # Children match
    my $matches = [];

    # Children
    if (@{$self->children}) {
        foreach my $child (@{$self->children}) {

            # Match?
            $matches = $child->_match($method => $path);
            last if $matches;

        }
        return unless $matches;
    }


    # Format and Method
    unless (@{$self->children}) {
        $self->_match_method($method) || return;
        $self->_match_format($request_format) || return;
    }

    # Match object
    my $match;

    if ($self->_is_bridge) {
        $match = Forward::Routes::Match->new;
        $match->is_bridge(1);

        # make earlier captures available to bridge
        if (my $m = $matches->[0]) {
            $match->_add_params(\%{$m->captures});
            $match->_add_captures(\%{$m->captures});
            $match->_add_name($m->name);
        }

        unshift @$matches, $match;
    }
    elsif (!$matches->[0]){
        $match = $matches->[0] = Forward::Routes::Match->new;
    }
    else {
        $match = $matches->[0];
    }

    my $captures_hash = $self->_captures_to_hash(@$captures);

    # Merge defaults and captures, Copy! of $self->defaults
    $match->_add_params({%{$self->defaults}, %$captures_hash});

    # Format
    unless (@{$self->children}) {
        $match->_add_params({format => $request_format}) if $self->{format};
    }

    # Captures
    $match->_add_captures($captures_hash);

    # Name
    $match->_add_name($self->name);

    return $matches;
}


sub _match_current_pattern {
    my ($self, $path_ref) = @_;

    # Pattern
    my $regex = $self->pattern->compile->pattern;
    my @captures = ($$path_ref =~ m/$regex/);
    return unless @captures;

    # Remove 1 at the end of array if no real captures present
    splice @captures, @{$self->pattern->captures};

    # Replace matching part
    $$path_ref =~ s/$regex//;



    return \@captures;
}


sub _captures_to_hash {
    my $self = shift;
    my (@captures) = @_;

    my $captures = {};

    my $defaults = $self->{defaults};

    foreach my $name (@{$self->pattern->captures}) {
        my $capture = shift @captures;

        if (defined $capture) {
            $captures->{$name} = $capture;
        }
        else {
            $captures->{$name} = $defaults->{$name} if defined $defaults->{$name};
        }
    }

    return $captures;
}


sub constraints {
    my $self = shift;

    return $self->pattern->constraints unless defined $_[0];

    my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    $self->pattern->constraints($constraints);

    return $self;
}


sub _match_method {
    my ($self, $value) = @_;

    return 1 unless defined $self->method;

    return unless defined $value;

    return !!grep { $_ eq $value } @{$self->method};
}


sub build_path {
    my ($self, $name, @params) = @_;

    my $child = $self->find_route($name);

    my $path = $child->_build_path(@params) if $child;

    # Format extension
    $path->{path} .= '.'.$child->{format}->[0] if $child->{format} && $child->{format}->[0];

    # Method
    $path->{method} = $child->{method}->[0] if $child->{method};

    $path->{path} =~s/^\/// if $path;

    return $path if $path;

    croak qq/Unknown name '$name' used to build a path/;
}


sub _build_path {
    my ($self, %params) = @_;

    my $path = {};
    $path->{path} = '';

    if ($self->{parent}) {
        $path = $self->{parent}->_build_path(%params);
    }

    # Return path if current route has no pattern
    return $path unless $self->{pattern} && defined $self->{pattern}->pattern;

    $self->{pattern}->compile;

    # Path parts by optional level
    my $parts = {};

    # Capture is required if other captures have already been defined in same optional group
    my $existing_capture = {};

    # No captures allowed if other captures empty in same optional group
    my $empty_capture = {};

    # Optional depth
    my $depth = 0;

    # Use pre-generated pattern->path in case no captures exist for current route
    if (my $new_path = $self->{pattern}->path) {
        $path->{path} = $path->{path}.$new_path;
        return $path;
    }

    foreach my $part (@{$self->{pattern}->parts}) {
        my $type = $part->{type};
        my $name = $part->{name} || '';

        # Open group
        if ($type eq 'open_group') {
            $depth++ if ${$part->{optional}};
            next;
        }

        # Close optional group
        if ($type eq 'close_group' && ${$part->{optional}}) {

            # Only pass group content to lower levels if captures have values
            if ($existing_capture->{$depth}) {

                # push data to optional level
                push @{$parts->{$depth-1}}, @{$parts->{$depth}};

                # error, if lower level optional group has emtpy captures, but current
                # optional group has filled captures
                $self->capture_error($empty_capture->{$depth-1})
                  if $empty_capture->{$depth-1};

                # all other captures in lower level must have values now
                $existing_capture->{$depth-1} += $existing_capture->{$depth};
            }

            $existing_capture->{$depth} = 0;
            $empty_capture->{$depth} = undef;
            $parts->{$depth} = [];

            $depth--;

            next;
        }
        # Close non optional group
        elsif ($type eq 'close_group' && !${$part->{optional}}) {
            next;
        }

        my $path_part;

        # Capture
        if ($type eq 'capture') {

            # Param
            $path_part = $params{$name};
            $path_part = defined $path_part ? $path_part : $self->{defaults}->{$name};

            if (!$depth && !defined $path_part) {
                $self->capture_error($name);
            }
            elsif ($depth && !defined $path_part) {

                # Capture value has to be passed if other captures in same
                # group have already been passed

                $self->capture_error($name) if $existing_capture->{$depth};

                # Save capture as empty as following captures in same group
                # have to be empty as well
                $empty_capture->{$depth} = $name;

                next;

            }
            elsif ($depth && defined $path_part) {

                # Earlier captures in same group can not be empty
                $self->capture_error($empty_capture->{$depth})
                  if $empty_capture->{$depth};

                $existing_capture->{$depth} = 1;
            }

            # Constraint
            my $constraint = $part->{constraint};
            if (defined $constraint) {
                croak qq/Param '$name' fails a constraint/
                  unless $path_part =~ m/^$constraint$/;
            }

        }
        # Globbing
        elsif ($type eq 'glob') {
            my $name = $part->{name};

            croak qq/Required glob param '$name' was not passed when building a path/
              unless exists $params{$name};

            $path_part = $params{$name};
        }
        # Text
        elsif ($type eq 'text') {
            $path_part = $part->{text};
        }
        # Slash
        elsif ($type eq 'slash') {
            $path_part = '/';
        }

        # Push param in optional group array
        push @{$parts->{$depth}}, $path_part;

    }

    my $new_path = join('' => @{$parts->{0}});

    if ($self->{parent}) {
        $path->{path} = $path->{path}.$new_path;
    }
    else {
        $path->{path} = $new_path;
    }

    return $path;

}


sub capture_error {
    my ($self, $capture_name) = @_;

    croak qq/Required param '$capture_name' was not passed when building a path/;
}


sub children {
    my $self = shift;

    $self->{children} ||= [];
    return $self->{children} unless $_[0];

    $self->{children} = $_[0];
    return $self;
}


sub parent {
    my $self = shift;

    return $self->{parent} unless $_[0];

    $self->{parent} = $_[0];

    weaken $self->{parent};

    return $self;

}


sub pattern {
    my $self = shift;
    my (@params) = @_;

    $self->{pattern} ||= Forward::Routes::Pattern->new;

    return $self->{pattern} unless @params;

    $self->{pattern}->pattern(@params);

    return $self;

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


sub _is_plural_resource {
    my $self = shift;

    return $self->{_is_plural_resource} unless defined $_[0];

    $self->{_is_plural_resource} = $_[0];

    return $self;
}


sub format {
    my $self = shift;
    my (@params) = @_;

    return $self->{format} unless @params;

    # no format constraint, no format matching performed
    if (!defined($params[0])) {
        $self->{format} = undef;
        return $self;
    }

    my $formats = ref $params[0] eq 'ARRAY' ? $params[0] : [@params];

    @$formats = map {lc $_} @$formats;

    $self->{format} = $formats;

    return $self;
}


sub _match_format {
    my ($self, $request_format) = @_;

    return 1 unless defined $self->format;

    my @success = grep { $_ eq $request_format } @{$self->format};

    return unless @success;

    return 1;
}

1;
__END__
=head1 Name

Forward::Routes - restful routes for web framework developers

=head1 Description

Instead of letting a web server like Apache decide which files to serve based
on the provided URL, the whole work can be done by your framework using the
L<Forward::Routes> module.

Ruby on Rails and Perl's Mojolicious make use of routes. Forward::Routes, in
contrast to that, tries to provide the same or even better functionality
without the tight couplings with a full featured framework.

Think of routes as kind of simplified regular expressions! First of all, a
bunch of routes is defined. Each route contains information on

=over 2

=item *

what kind of URLs to match

=item *

what to do in case of a match

=back

Finally, the request method and path of a users HTTP request are passed to
search for a matching route.


=head2 1. Routes setup

Each route represents a specific URL or a bunch of URLs (if placeholders are
used). The URL path pattern is defined via the C<add_route> command. A route
also contains information on what to do in case of a match. A common use
case is to provide controller and action defaults, so the framework knows
which controller method to execute in case of a match:

    # create a routes root object
    my $routes = Forward::Routes->new;

    # add a new route with a :city placeholder and controller and action defaults
    $routes->add_route('/towns/:city')->defaults(controller => 'World', action => 'cities');

=head2 2. Search for a matching route

After the setup has been done, the method and path of a current HTTP request
can be passed to the routes root object to search for a matching route.

The match method returns an array ref of L<Forward::Routes::Match> objects in
case of a match, or undef if there is no match. Unless advanced techniques
such as bridges are used, the array ref contains no more than one match object
($matches->[0]).

    # get request path and method (e.g. from a Plack::Request object)
    my $path   = $req->path_info;
    my $method = $req->method;

    # search routes
    my $matches = $routes->match($method => $path);

The search ends as soon as a matching route has been found. As a result, if
there are multiple routes that might match, the route that has been defined
first wins.

    # $matches is an array ref of Forward::Routes::Match objects
    my $matches = $routes->match(GET => '/towns/paris');

    # exactly one match object is returned:
    # $match is a Forward::Routes::Match object
    my $match = $matches->[0];

    # $match->params->{controller} is "World"
    # $match->params->{action}     is "cities"
    # $match->params->{city}       is "paris"

Controller and action parameters can be used by your framework to execute the
desired controller method, while making default and placeholder values of the
matching route available to that method for further use.

If the passed path and method do not match against a defined route, an
undefined value is returned. Frameworks might render a 404 not found page in
such cases.

    # $matches is undef
    my $matches = $routes->match(get => '/hello_world');

The match object holds two types of parameters:

=over 2

=item *

default values of the matching route as defined earlier via the "defaults"
method

=item *

placeholder values extracted from the passed URL path

=back


=head1 Features and Methods

=head2 Add new routes

The C<add_route> method adds a new route to the parent route object (in simple
use cases, to the routes root object) and returns the new route object.

The passed parameter is the URL path pattern of the new route object. The URL
path pattern is kind of a simplified reqular expression for the path part of a
URL and is transformed to a real regular expression internally. It is used
later on to check whether the passed request path matches the route.

    $root = Forward::Routes->new;
    my $new_route = $root->add_route('foo/bar');

    my $m = $root->match(get => 'foo/bar');
    # $m->[0]->params is {}

    my $m = $r->match(get => 'foo/hello');
    # $m is undef;


=head2 Placeholders

Placeholders start with a colon and match everything except slashes. If the
route matches against the passed request method and path, placeholder values
can be retrieved from the returned match object.

    $r = Forward::Routes->new;
    $r->add_route(':foo/:bar');

    $m = $r->match(get => 'hello/there');
    # $m->[0]->params is {foo => 'hello', bar => 'there'};

    $m = $r->match(get => 'hello/there/you');
    # $m is undef


=head2 Optional Placeholders

Placeholders can be marked as optional by surrounding them with brackets and
a trailing question mark.

    $r = Forward::Routes->new;
    $r->add_route(':year(/:month/:day)?');

    $m = $r->match(get => '2009');
    # $m->[0]->params is {year => 2009}

    $m = $r->match(get => '2009/12');
    # $m is undef

    $m = $r->match(get => '2009/12/10');
    # $m->[0]->params is {year => 2009, month => 12, day => 10}


    $r = Forward::Routes->new;
    $r->add_route('/hello/world(-:city)?');

    $m = $r->match(get => 'hello/world');
    # $m->[0]->params is {}

    $m = $r->match(get => 'hello/world-paris');
    # $m->[0]->params is {city => 'paris'}


=head2 Grouping

Placeholders have to be surrounded with brackets if more than one placeholder
is put between slashes (grouping).

    $r = Forward::Routes->new;
    $r->add_route('world/(:country)-(:cities)');

    $m = $r->match(get => 'world/us-new_york');
    # $m->[0]->params is {country => 'us', cities => 'new_york'}


=head2 Constraints

By default, placeholders match everything except slashes. The C<constraints>
method allows to make placeholders more restrictive. The first passed
parameter is the name of the placeholder, the second parameter is a
Perl regular expression.

    $r = Forward::Routes->new;

    # placeholder only matches integers
    $r->add_route('articles/:id')->constraints(id => qr/\d+/);
    
    $m = $r->match(get => 'articles/abc');
    # $m is undef
    
    $m = $r->match(get => 'articles/123');
    # $m->[0]->params is {id => 123}


=head2 Defaults

The C<defaults> method allows to add default values to a route. If the route
matches against the passed request method and path, default values can be
retrieved from the returned match object.

    $r = Forward::Routes->new;
    $r->add_route('articles')
      ->defaults(first_name => 'Kevin', last_name => 'Smith');

    $m = $r->match(get => 'articles');
    # $m->[0]->params is {first_name => 'Kevin', last_name => 'Smith'}


=head2 Optional Placeholders and Defaults

Placeholders are automatically filled with default values if the route
would not match otherwise.

    $r = Forward::Routes->new;
    $r->add_route(':year(/:month)?/:day')->defaults(month => 1);

    $m = $r->match(get => '2009');
    # $m is undef

    $m = $r->match(get => '2009/12');
    # $m->[0]->params is {year => 2009, month => 1, day => 12}

    $m = $r->match(get => '2009/2/3');
    # $m->[0]->params is {year => 2009, month => 2, day => 3};


=head2 Shortcut for Action and Controller Defaults

The C<to> method provides a shortcut for action and controller defaults.

    $r = Forward::Routes->new;

    $r->add_route('articles')
      ->to('Foo#bar');

    # is a shortcut for
    $r->add_route('articles')
      ->defaults(controller => 'Foo', action => 'bar');

    $m = $r->match(get => 'articles');
    # $m->[0]->params is {controller => 'Foo', action => 'bar'}


=head2 Request Method Constraints

The C<via> method sets the HTTP request method required for a route to match.
If no method is set, the request method has no influence on the search for a
matching route.

    $r = Forward::Routes->new;
    $r->add_route('logout')->via('post');

    my $m = $r->match(get => 'logout');
    # $m is undef
    
    my $m = $r->match(post => 'logout');
    # $m->[0] is {}

All child routes inherit the method constraint of their parent, unless the
method constraint of the child is overwritten.


=head2 Format Constraints

The C<format> method restricts the allowed formats of a URL path. If the route
matches against the passed request method and path, the format value can be
retrieved from the returned match object.

    $r = Forward::Routes->new;
    $r->add_route(':foo/:bar')->format('html','xml');

    $m = $r->match(get => 'hello/there.html');
    # $m->[0]->params is {foo => 'hello', bar => 'there', format => 'html'}

    $m = $r->match(get => 'hello/there.xml');
    # $m->[0]->params is {foo => 'hello', bar => 'there', format => 'xml'}

    $m = $r->match(get => 'hello/there.jpeg');
    # $m is undef


All child routes inherit the format constraint of their parent, unless the
format constraint of the child is overwritten. For example, adding a format
constraint to the route root object affects all child routes added
via add_route.
    
    my $root = Forward::Routes->new->format('html');
    $root->add_route('foo')->format('xml');
    $root->add_route('baz');

    $m = $root->match(get => 'foo.html');
    # $m is undef;
    
    $m = $root->match(get => 'foo.xml');
    # $m->[0]->params is {format => 'xml'};

    $m = $root->match(get => 'baz.html');
    # $m->[0]->params is {format => 'html'};

    $m = $root->match(get => 'baz.xml');
    # $m is undef;

If no format constraint is added to a route and the route's parents also have
no format constraints, there is also no format validation taking place. This
might cause kind of unexpected behaviour when dealing with placeholders:

    $r = Forward::Routes->new;
    $r->add_route(':foo/:bar');

    $m = $r->match(get => 'hello/there.html');
    # $m->[0]->params is {foo => 'hello', bar => 'there.html'}

If this is not what you want, an empty format constraint can be passed explicitly:

    $r = Forward::Routes->new->format('');
    $r->add_route(':foo/:bar');

    $m = $r->match(get => 'hello/there.html');
    # $m->[0] is undef

    $m = $r->match(get => 'hello/there');
    # $m->[0]->params is {foo => 'hello', bar => 'there'}


=head2 Naming

Each route can get a name through the C<name> method. Names are required to
make routes reversible (see C<build_path>).

    $r = Forward::Routes->new;
    $r->add_route('logout')->name('foo');


=head2 Path Building

Routes are reversible, i.e. paths can be generated through the C<build_path>
method. The first parameter is the name of the route. If the route consists of
placeholders which are not optional, placeholder values have to be passed as
well to generate the path, otherwise an exception is thrown.
The C<build_path> method returns a hash ref with the keys "method" and "path".

    $r = Forward::Routes->new;
    $r->add_route('world/(:country)-(:cities)')->name('hello')->via('post');

    my $path = $r->build_path('hello', country => 'us', cities => 'new_york')
    # $path->{path}   is 'world/us-new_york';
    # $path->{method} is 'post';

Path building is useful to build tag helpers that can be used in templates.
For example, a link_to helper might generate a link with the help of a route
name: link_to('route_name', placeholder => 'value'). In contrast to hard
coding the URL in templates, routes could be changed and all links in your
templates would get adjusted automatically.


=head2 Chaining

All methods can be chained.

    $r = Forward::Routes->new;
    my $articles = $r->add_route('articles/:id')
      ->defaults(first_name => 'foo', last_name => 'bar')
      ->format('html')
      ->constraints(id => qr/\d+/)
      ->name('hot')
      ->to('Hello#world')
      ->via('get','post');


=head2 Nested Routes

New routes cannot only be added to the routes root object, but to any route.
Building deep routes trees might result in performance gains in larger
projects with many routes, as the amount of regular expression searches can
be reduced this way.

    # nested routes
    $root = Forward::Routes->new;
    $nested1 = $root->add_route('foo1');
    $nested1->add_route('bar1');
    $nested1->add_route('bar2');
    $nested1->add_route('bar3');
    $nested1->add_route('bar4');
    $nested1->add_route('bar5');

    $nested2 = $root->add_route('foo2');
    $nested2->add_route('bar5');

    $m = $r->match(get => 'foo2/bar5');
    # 3 regular expression searches performed

    # alternative:
    $root = Forward::Routes->new;
    $root->add_route('foo1/bar1');
    $root->add_route('foo1/bar2');
    $root->add_route('foo1/bar3');
    $root->add_route('foo1/bar4');
    $root->add_route('foo1/bar5');
    $root->add_route('foo2/bar5');
    # 6 regular expression searches performed


=head2 Resource Routing

The C<add_resources> method enables Rails like resource routing.

Please look at L<Forward::Guides::Routes::Resources> for more in depth
documentation on resourceful routes.

    $r = Forward::Routes->new;
    $r->add_resources('users', 'photos', 'tags');

    $m = $r->match(get => 'photos');
    # $m->[0]->params is {controller => 'Photos', action => 'index'}

    $m = $r->match(get => 'photos/1');
    # $m->[0]->params is {controller => 'Photos', action => 'show', id => 1}

    $m = $r->match(put => 'photos/1');
    # $m->[0]->params is {controller => 'Photos', action => 'update', id => 1}

    my $path = $r->build_path('photos_update', id => 987)
    # $path->{path} is 'photos/987'
    # $path->{method} is 'put'

Resource routing is quite flexible and offers many options for customization:
L<Forward::Guides::Routes::ResourceCustomization>

Please look at L<Forward::Guides::Routes::NestedResources> for more in depth
documentation on nested resources.

=head2 Bridges

    $r = Forward::Routes->new;
    my $bridge = $r->bridge('admin')->to('Check#authentication');
    $bridge->add_route('foo')->to('My#stuff');

    $m = $r->match(get => 'admin/foo');
    # $m->[0]->params is {controller => 'Check', action => 'authentication'}
    # $m->[1]->params is {controller => 'My', action => 'stuff'}


=head1 Author

ForwardEver

=head1 Copyright and License

Copyright (C) 2011, ForwardEver

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 Credits

Path matching and path building inspired by Viacheslav Tykhanovskyi's Router module
L<https://github.com/vti/router>

Concept of nested routes and bridges inspired by Sebastian Riedel's Mojolicious::Routes module
L<https://github.com/kraih/mojo/tree/master/lib/Mojolicious/Routes>

Concept of restful resources inspired by Ruby on Rails

=cut
