use 5.010;
use strict;
use warnings;

package MyWeb::Form::Register;
# ABSTRACT: goes here
# VERSION

use HTML::FormHandler::Moose;
use Moose::Util::TypeConstraints;

extends 'MyWeb::Form::Base';

has check_user_avail => (
  traits   => ['Code'],
  isa      => 'CodeRef',
  required => 1,
  handles  => { 'user_avail' => 'execute' },
);

has check_email_avail => (
  traits   => ['Code'],
  isa      => 'CodeRef',
  required => 1,
  handles  => { 'email_avail' => 'execute' },
);

has_field 'user' => (
  required     => 1,
  type         => 'Text',
  label        => 'Username',
  element_attr => { placeholder => "username" },
  element_class => [qw/input-xlarge/],
);

sub validate_user {
  my ( $self, $field ) = @_;
  $self->user_avail( $field->value )
    or $field->add_error("That username is not available. Please pick another.");
}

has_field 'password' => (
  required => 1,
  type     => 'Password',
  password => 0, # fill in again if other things failed to validate
  element_class => [qw/input-xlarge/],
);

has_field 'email' => (
  required     => 1,
  type         => 'Email',
  label        => 'Email',
  element_attr => { placeholder => 'you@example.com' },
  element_class => [qw/input-xlarge/],
);

sub validate_email {
  my ( $self, $field ) = @_;
  $self->email_avail( $field->value )
    or $field->add_error("That email is already in use.");
}

has_field 'submit' => (
  type          => 'Submit',
  default       => 'Sign up',
  element_class => [qw/btn btn-primary/],
);

no HTML::FormHandler::Moose;

1;

