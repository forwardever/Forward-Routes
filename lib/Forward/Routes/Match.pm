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


sub _add_name {
    my $self = shift;
    my (@params) = @_;

    $self->{name} = $params[0] if @params;

    return $self;
}


sub _add_namespace {
    my $self = shift;
    my (@params) = @_;

    $self->{namespace} = $params[0] if @params;

    return $self;
}


sub _add_app_namespace {
    my $self = shift;
    my (@params) = @_;

    $self->{app_namespace} = $params[0] if @params;

    return $self;
}


sub params {
    my $self = shift;
    my ($key) = @_;

    # Initialize
    $self->{params} ||= {};

    # Get hash
    return $self->{params} unless defined $key && length $key;

    # Get hash value
    return $self->{params}->{$key};
}


sub captures {
    my $self = shift;
    my ($key) = @_;

    # Initialize
    $self->{captures} ||= {};

    # Get hash
    return $self->{captures} unless defined $key && length $key;

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


sub name {
    my $self = shift;
    return $self->{name};
}


sub controller {
    my $self = shift;
    return $self->{params}->{controller};
}


sub namespace {
    my $self = shift;
    return $self->{namespace};
}


sub app_namespace {
    my $self = shift;
    return $self->{app_namespace};
}


sub class {
    my $self = shift;

    return undef unless $self->{params}->{controller};

    my @class;

    push @class, $self->{app_namespace} if $self->{app_namespace};

    push @class, $self->{namespace} if $self->{namespace};

    push @class, $self->{params}->{controller};

    return join('::', @class);
}


sub action {
    return shift->{params}->{action};
}


1;
