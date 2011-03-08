package Forward::Routes;

use strict;
use warnings;

use Forward::Routes::Match;
use Forward::Routes::Pattern;
use Scalar::Util qw/weaken/;
use Carp 'croak';

our $VERSION = '0.05';

sub new {
    my $class = shift;

    $class = ref $class if ref $class;

    my $self = bless {}, $class;

    return $self->initialize(@_);
}

sub initialize {
    my $self   = shift;

    # Pattern
    my $pattern = @_ % 2 ? shift : undef;

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

    # Save to pattern
    $self->pattern->pattern($pattern) if defined $pattern;
    $self->constraints(delete $params->{constraints});

    return $self;

}

sub prefixed_with {
    my $self = shift;
    my $prefix = shift;

    my $router = Forward::Routes->new(prefix => $prefix);
    $router->{patterns} = $self->{patterns};

    return $router;
}

sub add_route {
    my $self = shift;

    my $child = $self->new(@_);

    push @{$self->children}, $child;

    $child->parent($self);

    return $child;
}

sub add_resource {
    my $self = shift;
    my $name = shift;

    my $controller = $name;

    my $resource = $self->add_route("$name");

    $resource->add_route(
        '/new',
        method => 'get',
        to     => "$controller#create_form",
        name   => $name.'_create_form'
    );

    $resource->add_route(
        '/edit',
        method => 'get',
        to     => "$controller#update_form",
        name   => $name.'_update_form'
    );


    my $nested = $resource->add_route;
    $nested->add_route(
        method => 'post',
        to     => "$controller#create",
        name   => $name.'_create'
    );

    $nested->add_route(
        method => 'get',
        to     => "$controller#show",
        name   => $name.'_show'
    );

    $nested->add_route(
        method => 'put',
        to     => "$controller#update",
        name   => $name.'_update'
    );

    $nested->add_route(
        method => 'delete',
        to     => "$name#delete",
        name   => $name.'_delete'
    );

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
        my $resource = $self->add_route("$name", _parent_is_plural_resource => $name);

        # nested resources
        my $id_prefix = '';
        if ($parent_resource) {
            $id_prefix = $name.'_';
        }

        # resource
        $resource->add_route(
            method => 'get',
            to     => "$name#index",
            name   => $name.'_index'
        );
        $resource->add_route(
            method => 'post',
            to     => "$name#create",
            name   => $name.'_create'
        );

        # new resource item
        $resource->add_route(
            '/new',
            method => 'get',
            to     => "$name#create_form",
            name   => $name.'_create_form'
        );

        # modify resource item
        my $nested = $resource->add_route(
            ':'.$id_prefix.'id'
        );

        $nested->add_route(
            method => 'get',
            to     => "$name#show",
            name   => $name.'_show'
        );
        $nested->add_route(
            method => 'put',
            to     => "$name#update",
            name   => $name.'_update'
        );
        $nested->add_route(
            method => 'delete',
            to     => "$name#delete",
            name   => $name.'_delete'
        );
        $nested->add_route(
            'edit',
            method => 'get',
            to     => "$name#update_form",
            name   => $name.'_update_form'
        );
        $nested->add_route(
            'delete',
            method => 'get',
            to     => "$name#delete_form",
            name   => $name.'_delete_form'
        );

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
    my $self = shift;
    my $name = shift;

    return $self->{name} unless defined $name;

    $self->{name} = $name;

    return $self;
}

sub to {
    my $self = shift;
    my $to   = shift;

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
    my $self = shift;
    my $name = shift;

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
    my $self   = shift;
    my $method = shift;
    my $path   = shift || die 'missing path';

    # Leading slash
    $path = "/$path" unless $path =~ m{ \A / }x;

    # Search for match
    my $match = $self->_match(lc($method) => $path);
    return unless $match;

    return [$match];
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
    my $self   = shift;
    my $method = shift;
    my $path   = shift;

    # Method
    return unless $self->_match_method($method);

    # Current pattern match
    my $captures = [];
    if (defined $self->pattern->pattern) {
        $captures = $self->_match_current_pattern(\$path) || return;
    }

    # No Match, as path not empty, but further children
    return if length($path) && !@{$self->children};

    # Children match
    my $match;

    # Format
    my $format = $self->_match_format(\$path);
    return unless defined $format;

    # Children
    if (@{$self->children}) {
        foreach my $child (@{$self->children}) {

            # Match?
            $match = $child->_match($method => $path);
            last if $match;

        }
        return unless $match;
    }

    # Match object
    $match ||= Forward::Routes::Match->new;
    my $params = $self->prepare_params(@$captures);
    $match->add_params($params);
    $match->add_params({format => $format}) if length($format);

    return $match;
}

sub _match_current_pattern {
    my $self     = shift;
    my $path_ref = shift;

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
    my $self = shift;
    my @captures = @_;

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
    my $self  = shift;
    my $value = shift;

    return 1 unless defined $self->method;

    return unless defined $value;

    return !!grep { $_ eq $value } @{$self->method};
}

sub build_path {
    my $self = shift;
    my $name = shift;

    my $child = $self->find_route($name);

    my $path = $child->_build_path(@_) if $child;

    $path->{path} =~s/^\/// if $path;

    return $path if $path;

    croak qq/Unknown name '$name' used to build a path/;
}

sub _build_path {
    my $self   = shift;
    my %params = @_;

    my $path = {};
    $path->{path} = '';

    if ($self->{parent}) {
        $path = $self->{parent}->_build_path(%params);
    }

    # Method
    $path->{method} = $self->{method}->[0] if $self->{method};

    # Return path if current route has no pattern
    return $path unless defined $self->{pattern}->pattern;

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
            $path_part //= $self->{defaults}->{$name};

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
            if (defined(my $constraint = $part->{constraint})) {
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
    my $self         = shift;
    my $capture_name = shift;

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
    my $self = shift;
    my $path = shift;

    return '' unless defined $self->format;

    my @match = ($$path =~m/\.([\a-zA-Z0-9]{1,4})$/);

    my $format = defined $1 ? $1 : '';

    my @success = grep { $_ eq $format } @{$self->format};

    return unless @success;

    $$path =~s/\.[\a-zA-Z0-9]{1,4}$//;

    return $format;

}

1;
