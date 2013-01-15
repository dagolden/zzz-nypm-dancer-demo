use v5.10;
use strict;
use warnings;

package MyWeb::Model::User;

# ABSTRACT: No abstract given for MyWeb::Model::User
# VERSION

use Authen::Passphrase::BlowfishCrypt;
use Data::Entropy::Algorithms qw/rand_bits/;
use MIME::Base64 qw/encode_base64url/;
use Moose 2;
use MooseX::Aliases;
use MooseX::Types::Email::Loose qw/EmailAddressLoose/;
use autodie 2.00;
use namespace::autoclean;

with 'Mongoose::Document' => { -pk => [qw/u/], };

has u => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    alias    => 'user',
);

has p => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    alias   => 'hashed_password',
);

has e => (
    is       => 'rw',
    isa      => EmailAddressLoose,
    required => 1,
    alias    => 'email',
);

has ev => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    alias   => 'email_valid',
);

has _passphrase => (
    is         => 'ro',
    clearer    => 'clear__passphrase',
    isa        => 'Authen::Passphrase',
    lazy_build => 1,
    traits     => [qw/DoNotMongoSerialize/],
);

sub _build__passphrase {
    my ($self) = @_;
    return Authen::Passphrase::BlowfishCrypt->from_crypt( $self->hashed_password );
}

#--------------------------------------------------------------------------#
# Query helpers
#--------------------------------------------------------------------------#

sub find_user {
    my ( $self, $username ) = @_;
    return $self->find_one( { u => $username } );
}

sub find_by_email {
    my ( $self, $email ) = @_;
    return $self->find_one( { e => $email } );
}

#--------------------------------------------------------------------------#
# Password operations
#--------------------------------------------------------------------------#

sub matches_password {
    my ( $self, $password ) = @_;
    return unless length $self->hashed_password;
    return $self->_passphrase->match($password);
}

sub set_password {
    my ( $self, $password, $cost ) = @_;
    $cost //= 13;

    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
        cost        => $cost,
        salt_random => 1,
        passphrase  => $password,
    );

    $self->hashed_password( $ppr->as_crypt );
    $self->clear__passphrase;
    return 1;
}

sub scramble_password {
    my ($self) = @_;
    my $cost = $self->_passphrase->cost; # preserve current cost
    $self->set_password( encode_base64url( rand_bits(120) ), $cost );
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;

# vim: ts=4 sts=4 sw=4 et:
