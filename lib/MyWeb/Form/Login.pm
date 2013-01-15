use 5.010;
use strict;
use warnings;

package MyWeb::Form::Login;
# ABSTRACT: goes here
# VERSION

use HTML::FormHandler::Moose;
use Moose::Util::TypeConstraints;

extends 'MyWeb::Form::Base';

has check_user => (
    traits   => ['Code'],
    isa      => 'CodeRef',
    required => 1,
    handles  => { 'found_user' => 'execute' },
);

has check_password => (
    traits   => ['Code'],
    isa      => 'CodeRef',
    required => 1,
    handles  => { 'matches_password' => 'execute' },
);

has_field 'user' => (
    type         => 'Text',
    label        => 'Username',
    element_attr => { placeholder => "Your user name, not your email" },
);

has_field 'password' => (
    type         => 'Password',
    element_attr => { placeholder => "Your password" },
);

has_field 'submit' => (
    type          => 'Submit',
    default       => 'Sign in',
    element_class => [qw/btn btn-primary/],
);

sub validate {
    my ($self) = @_;

    my $user     = $self->field("user");
    my $password = $self->field("password");

    if ( !$self->found_user( $user->value ) ) {
        $user->add_error("Unknown user");
    }
    elsif ( !$self->matches_password( $password->value ) ) {
        $password->add_error("Incorrect password");
    }
    return;
}

no HTML::FormHandler::Moose;

1;

