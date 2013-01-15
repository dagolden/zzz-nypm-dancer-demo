use 5.010;
use strict;
use warnings;

package MyWeb::Form::ChangePassword;
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

has check_old_password => (
  traits   => ['Code'],
  isa      => 'CodeRef',
  required => 1,
  handles  => { 'matches_old_password' => 'execute' },
);

has_field 'old_password' => (
  type     => 'Password',
  label    => 'Old Password',
  password => 0, # fill in again if other things failed to validate
);

has_field 'spacer' => (
  type  => 'NonEditable',
  label => '',
  value => '',
);

has_field 'password' => (
  type  => 'Password',
  label => 'New Password',
);

has_field 'password_confirm' => (
  type  => 'PasswordConf',
  label => 'Confirm New Password',
);

has_field 'submit' => (
  type          => 'Submit',
  default       => 'Change password',
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
  my $old_pw = $self->field("old_password");
  if ( $old_pw->is_active && !$self->matches_old_password( $old_pw->value ) ) {
    $old_pw->add_error("Current password incorrect");
  }
}

no HTML::FormHandler::Moose;

1;

