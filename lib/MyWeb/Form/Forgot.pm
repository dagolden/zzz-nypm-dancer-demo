use 5.010;
use strict;
use warnings;

package MyWeb::Form::Forgot;
# ABSTRACT: goes here
# VERSION

use HTML::FormHandler::Moose;
use Moose::Util::TypeConstraints;

extends 'MyWeb::Form::Base';

has cancel_url => (
  is       => 'ro',
  isa      => 'URI',
  required => 1,
);

has check_user => (
  traits   => ['Code'],
  isa      => 'CodeRef',
  required => 1,
  handles  => { 'found_user' => 'execute' },
);

has check_email => (
  traits   => ['Code'],
  isa      => 'CodeRef',
  required => 1,
  handles  => { 'found_email' => 'execute' },
);

has_field 'user' => (
  type         => 'Text',
  label        => 'Username',
  element_attr => { placeholder => "Your username" },
);

has_field 'comment' => (
  type  => 'NonEditable',
  label => '',
  value => 'or',
);

has_field 'email' => (
  type         => 'Email',
  label        => 'Email',
  element_attr => { placeholder => 'you@example.com' },
);

has_field 'submit' => (
  type          => 'Submit',
  default       => 'Reset my password',
  element_class => [qw/btn btn-primary/],
  tags          => { build_after_element => '_cancel_button' },
);

sub _cancel_button {
  my ($self) = @_;
  my $url = $self->cancel_url;
  return qq{<a class="btn" href="$url">Cancel</a>};
}

sub validate {
  my ($self) = @_;

  my $user  = $self->field("user");
  my $email = $self->field("email");

  if ( $user->value ) {
    $user->add_error("Unknown user")
      unless $self->found_user( $user->value );
  }
  elsif ( $email->value ) {
    $self->field("email")->add_error("Unknown email address")
      unless $self->found_email( $email->value );
  }
  else {
    $self->clear_form_errors;
    $self->add_form_error("You must provide username or an email address");
  }

  return;
}

no HTML::FormHandler::Moose;

1;

