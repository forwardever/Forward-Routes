package Forward::Routes::Resources;
use strict;
use warnings;
use parent qw/Forward::Routes/;

use Forward::Routes::Resources::Plural;
use Forward::Routes::Resources::Singular;
use Carp;


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self->initialize(@_);
}


sub add_member_route {
    my $self = shift;
    my ($pattern, @params) = @_;

    my $members = $self->members;

    # makes sure that inheritance works
    my $child = Forward::Routes->new($pattern, @params);
    $members->add_child($child);

    # name
    my $member_route_name = $pattern;
    $member_route_name =~s|^/||;
    $member_route_name =~s|/|_|g;


    # Auto set controller and action params and name
    $child->to($self->{_ctrl} . '#' . $member_route_name);
    $child->name($self->{name} . '_' . $member_route_name);

    return $child;
}


sub id_constraint {
}


sub init_options {
    my $self = shift;
    my ($options) = @_;

    # default
    $self->id_constraint(qr/[^.\/]+/);

    if ($options) {
        $self->id_constraint($options->{constraints}->{id}) if $options->{constraints}->{id};
        $self->{only} = $options->{only};
        $self->pattern->pattern($options->{as}) if exists $options->{as};
    }

    my $ns_name_prefix = $self->namespace ? Forward::Routes::Resources->namespace_to_name($self->namespace) . '_' : '';
    my $route_name = ($self->{nested_resources_parent_name} ? $self->{nested_resources_parent_name} . '_' : '') . $ns_name_prefix . $self->{resource_name};
    $self->name($route_name);

    $self->{resource_name_part} = $ns_name_prefix . $self->{resource_name};


    my $ctrl = Forward::Routes::Resources->format_resource_controller->($self->{resource_name});
    $self->_ctrl($ctrl);
}


sub members {
    my $self = shift;
    return $self;
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


sub _adjust_nested_resources {
    my $self = shift;
    my ($parent) = @_;

    $parent->_is_plural_resource || return;

    my $parent_name = $parent->{resource_name_part};

    my $parent_id_name = $self->singularize->($parent_name) . '_id';

    $self->pattern->pattern(':' . $parent_id_name . '/' . $self->{resource_name});
    $self->constraints($parent_id_name => $parent->{id_constraint});
    
    if (defined $parent->name) {
        $self->{nested_resources_parent_name} = $parent->name;
    }
}


sub _ctrl {
    my $self = shift;
    my (@params) = @_;

    return $self->{_ctrl} unless @params;

    $self->{_ctrl} = $params[0];

    return $self;
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


1;
