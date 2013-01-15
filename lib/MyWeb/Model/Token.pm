use v5.10;
use strict;
use warnings;

package MyWeb::Model::Token;

# ABSTRACT: No abstract given for MyWeb::Model::User
# VERSION

use MIME::Base64 qw/encode_base64url/;
use Data::Entropy::Algorithms qw/rand_bits/;
use Moose 2;
use MooseX::Aliases;
use autodie 2.00;
use namespace::autoclean;

with 'Mongoose::Document' => { -pk => [qw/t/], };

has t => (
  is      => 'rw',
  isa     => 'Str',
  alias   => 'token',
  default => sub { encode_base64url( rand_bits(192) ) },
);

has u => (
  is       => 'rw',
  isa      => 'Str',
  required => 1,
  alias    => 'user',
);

has y => (
  is       => 'rw',
  isa      => 'Str',
  required => 1,
  alias    => 'type',
);

has e => (
  is      => 'rw',
  isa     => 'Num',
  default => sub { int(time) + 24 * 3600 }, # 24 hours
  alias   => 'expiration',
);

has v => (
  is    => 'rw',
  isa   => 'Any',
  alias => 'value',
);

#--------------------------------------------------------------------------#
# Query helpers
#--------------------------------------------------------------------------#

sub find_token {
  my ( $self, $token_id ) = @_;
  return $self->find_one( { t => $token_id } );
}

__PACKAGE__->meta->make_immutable;
1;

=for Pod::Coverage method_names_here

=head1 SYNOPSIS

  use MyWeb::Model::Token;

=head1 DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

=head1 USAGE

Good luck!

=head1 SEE ALSO

Maybe other modules do related things.

=cut

# vim: ts=2 sts=2 sw=2 et:
