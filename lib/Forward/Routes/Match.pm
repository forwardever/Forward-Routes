package Forward::Routes::Match;

use strict;
use warnings;


sub new {
    return bless {}, shift;
}

sub _add_params {
    my $self   = shift;
    my $params = shift;

    %{$self->params} = (%$params, %{$self->params});

    return $self;
}


sub _add_captures {
    my $self   = shift;
    my $params = shift;

    %{$self->captures} = (%$params, %{$self->captures});

    return $self;
}


sub pattern {
    my $self   = shift;

    return $self->{pattern} unless defined $_[0];

    $self->{pattern} = $_[0];

    return $self;
}


sub params {
    my $self = shift;
    my (@params) = @_;

    # Initialize
    $self->{params} ||= {};

    # Get hash
    return $self->{params} unless $params[0];

    # Get hash value
    return $self->{params}->{$params[0]};
}


sub captures {
    my $self = shift;
    my (@params) = @_;

    # Initialize
    $self->{captures} ||= {};

    # Get hash
    return $self->{captures} unless $params[0];

    # Get hash value
    return $self->{captures}->{$params[0]};
}


sub is_bridge {
    my $self = shift;

    return $self->{is_bridge} unless defined $_[0];

    $self->{is_bridge} = $_[0];

    return $self;
}



1;
