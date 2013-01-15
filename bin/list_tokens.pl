#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Dancer;
use Dancer::Plugin::Mongoose;

my $cursor = schema("token")->find;
while ( my $token = $cursor->next ) {
  my $link = "http://0:5000/confirm/" . $token->t;
  printf( "%s %10s %s\n", $token->type, $token->user, $link );
}

