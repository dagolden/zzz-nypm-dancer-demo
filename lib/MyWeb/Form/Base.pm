use 5.010;
use strict;
use warnings;

package MyWeb::Form::Base;
# ABSTRACT: goes here
# VERSION

use HTML::FormHandler::Moose;

extends 'HTML::FormHandler';
with 'MyWeb::FormHandler::Widget::Theme::Bootstrap';

has "+is_html5" => ( default => 1 );

has '+error_message' => ( default => "Whoops!  Please fix the problems below and try again." );

no HTML::FormHandler::Moose;

1;

