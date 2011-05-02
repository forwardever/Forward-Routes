package Forward::Routes;

use strict;
use warnings;

use Forward::Routes::Match;
use Forward::Routes::Pattern;
use Scalar::Util qw/weaken/;
use Carp 'croak';

our $VERSION = '0.15';

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
    $self->prefix(delete $params->{prefix});
    $self->name(delete $params->{name});
    $self->to(delete $params->{to});
    $self->_parent_is_plural_resource(delete $params->{_parent_is_plural_resource});
    $self->constraints(delete $params->{constraints});

    return $self;

}

sub prefixed_with {
    my ($self, $prefix) = @_;

    my $router = Forward::Routes->new(prefix => $prefix);
    $router->{patterns} = $self->{patterns};

    return $router;
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


sub add_singular_resources {
    my ($self, $name) = @_;

    my $controller = $name;

    my $resource = $self->add_route($name);

    $resource->add_route('/new')
      ->via('get')
      ->to("$controller#create_form")
      ->name($name.'_create_form');

    $resource->add_route('/edit')
      ->via('get')
      ->to("$controller#update_form")
      ->name($name.'_update_form');


    my $nested = $resource->add_route;
    $nested->add_route
      ->via('post')
      ->to("$controller#create")
      ->name($name.'_create');

    $nested->add_route
      ->via('get')
      ->to("$controller#show")
      ->name($name.'_show');

    $nested->add_route
      ->via('put')
      ->to("$controller#update")
      ->name($name.'_update');

    $nested->add_route
      ->via('delete')
      ->to("$name#delete")
      ->name($name.'_delete');

    return $self;
}


sub add_resources {
    my $self = shift;

    # Nestes resources
    my $parent_resource = $self->_parent_is_plural_resource
      if defined $self->_parent_is_plural_resource;

    if ($parent_resource) {

        # nested :id part becomes new parent
        $self = $self->children->[3];

        # rename parent placeholder
        $self->pattern->pattern(':'.$parent_resource.'_id')
          if $self->pattern->pattern eq ':id';
    }

    my $names = $_[0] && ref $_[0] eq 'ARRAY' ? [@{$_[0]}] : [@_];

    my $last_resource;

    foreach my $name (@$names) {
        my $resource = $self->add_route($name, _parent_is_plural_resource => $name);

        # nested resources
        my $id_prefix = '';
        if ($parent_resource) {
            $id_prefix = $name.'_';
        }

        # resource
        $resource->add_route
          ->via('get')
          ->to("$name#index")
          ->name($name.'_index');

        $resource->add_route
          ->via('post')
          ->to("$name#create")
          ->name($name.'_create');

        # new resource item
        $resource->add_route('/new')
          ->via('get')
          ->to("$name#create_form")
          ->name($name.'_create_form');

        # modify resource item
        my $nested = $resource->add_route(':'.$id_prefix.'id')
          ->constraints($id_prefix.'id' => qr/[^.\/]+/);

        $nested->add_route
          ->via('get')
          ->to("$name#show")
          ->name($name.'_show');

        $nested->add_route
          ->via('put')
          ->to("$name#update")
          ->name($name.'_update');

        $nested->add_route
          ->via('delete')
          ->to("$name#delete")
          ->name($name.'_delete');

        $nested->add_route('edit')
          ->via('get')
          ->to("$name#update_form")
          ->name($name.'_update_form');

        $nested->add_route('delete')
          ->via('get')
          ->to("$name#delete_form")
          ->name($name.'_delete_form');

        $last_resource = $resource;
    }

    return $last_resource;
}

sub defaults {
    my $self = shift;

    $self->{defaults} ||= {};

    return $self->{defaults} unless defined $_[0];

    my $defaults = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    %{$self->defaults} = (%{$self->defaults}, %$defaults);

    return $self;
}

sub name {
    my ($self, $name) = @_;

    return $self->{name} unless defined $name;

    $self->{name} = $name;

    return $self;
}

sub to {
    my ($self, $to) = @_;

    unless ($to) {
        my $d = $self->defaults;
        return $d->{controller}.'#'.$d->{action}
          if $d->{controller} && $d->{action};
        return;
    }

    my $params;
    @$params{qw/controller action/} = split '#' => $to;

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

    $path || die 'missing path';

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
    my ($self, $method, $path, $request_format) = @_;

    # Format
    if ($self->{format} && !defined($request_format)) {
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
            $matches = $child->_match($method => $path, $request_format);
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

    if (!$matches->[0] || $self->_is_bridge) {
        $match = Forward::Routes::Match->new;
        $match->is_bridge(1) if $self->_is_bridge;
        unshift @$matches, $match;
    }
    else {
        $match = $matches->[0];
    }

    my $params = $self->prepare_params(@$captures);
    $match->add_params($params);
    $match->add_params({format => $request_format}) if length($request_format);

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

sub prepare_params {
    my ($self, @captures) = @_;

    # Copy! of defaults
    my $params = {%{$self->defaults}};

    foreach my $name (@{$self->pattern->captures}) {
        last unless @captures;
        my $c = shift @captures;
        $params->{$name} = $c unless !defined $c;
    }

    return $params;

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


sub prefix {
    my $self = shift;

    return $self->{prefix} unless defined $_[0];

    $self->{prefix} = $_[0];

    return $self;
}


sub pattern {
    my $self = shift;

    $self->{pattern} ||= Forward::Routes::Pattern->new;

    return $self->{pattern};

}


sub _parent_is_plural_resource {
    my $self = shift;

    return $self->{_parent_is_plural_resource} unless defined $_[0];

    $self->{_parent_is_plural_resource} = $_[0];

    return $self;
}

sub format {
    my $self = shift;

    return $self->{format} unless defined $_[0];

    my $formats = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    @$formats = map {lc $_} @$formats;

    $self->{format} = $formats;

    return $self;
}

sub _match_format {
    my ($self, $request_format) = @_;

    $request_format ||= '';
    my $required_format = $self->{format} || [''];

    my @success = grep { $_ eq $request_format } @{$required_format};

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

=head3 1. Routes setup

Think of routes as kind of simplified regular expressions!

Each route represents a URL path pattern and holds a set of default values.

    # create a routes root object
    my $routes = Forward::Routes->new;

    # add a new route with a :city placeholder and controller and action defaults
    $routes->add_route('/towns/:city')->defaults(controller => 'world', action => 'cities');

=head3 2. Search for a matching route

After the setup has been done, the method and path of a current HTTP request
can be passed to the routes root object using the "match" method to search for
a matching route.

The match method returns an array ref of L<Forward::Routes::Match> objects in
case of a match, or undef if there is no match.

    # get request path and method (e.g. from a Plack::Request object)
    my $path   = $req->path_info;
    my $method = $req->method;

    # search routes
    my $matches = $routes->match($method => $path);


Unless advanced techniques such as bridges are used, the array ref contains
no more than one match object ($matches->[0]).

The search ends as soon as a matching route has been found. As a result, if
there are multiple routes that might match, the route that has been defined
first wins.

If the passed path and method do not match against a defined route, an
undefined value is returned. Frameworks might render a 404 not found page in
such cases.

    # $matches is undef
    my $matches = $routes->match(get => '/hello_world');


=head3 3. Parameters

The match object holds two types of parameters:

=over 2

=item *

default values of the matching route as defined earlier via the "defaults"
method

=item *

placeholder values extracted from the passed URL path

=back

Controller and action parameters can be used by your framework to execute the
desired controller method, while making default and placeholder values of the
matching route available to that method for further use.

    # $matches is an array ref
    my $matches = $routes->match(get => '/towns/paris');

    # $match is a Forward::Routes::Match object
    my $match = $matches->[0]

    # $match->params->{controller} is "world"
    # $match->params->{action}     is "cities"
    # $match->params->{city}       is "paris"


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
      ->to('foo#bar');

    # is a shortcut for
    $r->add_route('articles')
      ->defaults(controller => 'foo', action => 'bar');

    $m = $r->match(get => 'articles');
    # $m->[0]->params is {controller => 'foo', action => 'bar'}


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

Once a format constraint has been defined, all child routes inherit the
behaviour of their parents, unless they get format constraints themselves.
For example, adding a format constraint to the route root object affects all
child routes added via C<add_route>.
    
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
coding the URL in templates, routes could be changed an all links in your
templates would get adjusted automatically.


=head2 Chaining

All methods can be chained.

    $r = Forward::Routes->new;
    my $articles = $r->add_route('articles/:id')
      ->defaults(first_name => 'foo', last_name => 'bar')
      ->format('html')
      ->constraints(id => qr/\d+/)
      ->name('hot')
      ->to('hello#world')
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


=head2 Resources

The C<resources> method allows to generate Rails like resources.

Please look at L<Forward::Guides::Routes::RestfulResources> for more in depth
documentation.

    $r = Forward::Routes->new;
    $r->add_resources('users', 'photos', 'tags');

    $m = $r->match(get => 'photos');
    # $m->[0]->params is {controller => 'photos', action => 'index'}

    $m = $r->match(get => 'photos/1');
    # $m->[0]->params is {controller => 'photos', action => 'show', id => 1}

    $m = $r->match(put => 'photos/1');
    # $m->[0]->params is {controller => 'photos', action => 'update', id => 1}


=head2 Path Building and Resources

    $r = Forward::Routes->new;
    $r->add_resources('users', 'photos', 'tags');

    # $r->build_path('photos_update', id => 987)->{path} is 'photos/987'


=head2 Nested Resources

    $r = Forward::Routes->new;
    my $magazines = $r->add_resources('magazines');
    $magazines->add_resources('ads');

    $m = $r->match(get => 'magazines/1/ads/4');
    # $m->[0]->params is
    # {controller => 'ads', action => 'show', magazines_id => 1, ads_id => 4}


=head2 Bridges

    $r = Forward::Routes->new;
    my $bridge = $r->bridge('admin')->to('check#authentication');
    $bridge->add_route('foo')->to('my#stuff');

    $m = $r->match(get => 'admin/foo');
    # $m->[0]->params is {controller => 'check', action => 'authentication'}
    # $m->[1]->params is {controller => 'my', action => 'stuff'}


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
