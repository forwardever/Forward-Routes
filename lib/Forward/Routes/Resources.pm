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
    my (@params) = @_;

    my $child = Forward::Routes->new(@params);

    my $members = $self->_members;

    # makes sure that inheritance works
    $members->_add_child($child);

    # name
    my $name = $params[0];
    $name =~s|^/||;
    $name =~s|/|_|g;


    # custom namespace
    my $namespace = $self->namespace;

    my $ns_name_prefix = $namespace ? Forward::Routes::Resources->namespace_to_name($namespace).'_' : '';


    # Auto set controller and action params and name
    $child->to($self->{_ctrl}.'#'.$name);
    $child->name($ns_name_prefix.$self->{_name}.'_'.$name);

    return $child;

}


sub _members {
    my $self = shift;
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


sub _name {
    my $self = shift;
    my (@params) = @_;

    return $self->{_name} unless @params;

    $self->{_name} = $params[0];

    return $self;
}


sub _ctrl {
    my $self = shift;
    my (@params) = @_;

    return $self->{_ctrl} unless @params;

    $self->{_ctrl} = $params[0];

    return $self;
}


1;
