package Forward::Routes::Match;

use strict;
use warnings;


sub new {
    return bless {}, shift;
}

sub _add_params {
    my $self = shift;
    my ($params) = @_;

    %{$self->params} = (%$params, %{$self->params});

    return $self;
}


sub _add_captures {
    my $self = shift;
    my ($params) = @_;

    %{$self->captures} = (%$params, %{$self->captures});

    return $self;
}


sub pattern {
    my $self = shift;
    my ($pattern) = @_;

    return $self->{pattern} unless defined $pattern;

    $self->{pattern} = $pattern;

    return $self;
}


sub params {
    my $self = shift;
    my ($key) = @_;

    # Initialize
    $self->{params} ||= {};

    # Get hash
    return $self->{params} unless $key;

    # Get hash value
    return $self->{params}->{$key};
}


sub captures {
    my $self = shift;
    my ($key) = @_;

    # Initialize
    $self->{captures} ||= {};

    # Get hash
    return $self->{captures} unless $key;

    # Get hash value
    return $self->{captures}->{$key};
}


sub is_bridge {
    my $self = shift;
    my (@is_bridge) = @_;

    return $self->{is_bridge} unless @is_bridge;

    $self->{is_bridge} = $is_bridge[0];

    return $self;
}


1;
