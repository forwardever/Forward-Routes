package Forward::Routes::Match;

use strict;
use warnings;


sub new {
    return bless {}, shift;
}

sub add_params {
    my $self   = shift;
    my $params = shift;

    %{$self->params} = (%$params, %{$self->params});

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

    $self->{params} ||= {};
    return $self->{params} unless $_[0];

    $self->{params} = $_[0];
    return $self;
}


sub is_bridge {
    my $self = shift;

    return $self->{is_bridge} unless defined $_[0];

    $self->{is_bridge} = $_[0];

    return $self;
}



1;
