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
    my (@params) = @_;

    # Initialize
    $self->{params} ||= {};

    # Get hash
    return $self->{params} unless $params[0];

    # Get hash value
    return $self->{params}->{$params[0]};

}


sub is_bridge {
    my $self = shift;

    return $self->{is_bridge} unless defined $_[0];

    $self->{is_bridge} = $_[0];

    return $self;
}



1;
