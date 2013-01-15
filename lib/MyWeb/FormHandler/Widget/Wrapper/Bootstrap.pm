package MyWeb::FormHandler::Widget::Wrapper::Bootstrap;

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

with 'HTML::FormHandler::Widget::Wrapper::Base';

sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    my $output;
    # create attribute string for wrapper
    my $attr = $self->wrapper_attributes($result);
    my $div_class = "control-group";
    unshift @{$attr->{class}}, $div_class;
    my $attr_str = process_attrs( $attr );
    # wrapper is always a div
    $output .= qq{\n<div$attr_str>}
        if $self->do_wrapper;
    # render the label
    $output .= "\n" . $self->do_render_label($result, undef, ['control-label'] )
        if $self->do_label;
    $output .=  $self->get_tag('before_element');
    # the controls div for ... controls
    $output .= qq{\n<div class="controls">};
    # handle input-prepend and input-append
    if( $self->get_tag('input_prepend') || $self->get_tag('input_append') ||
            $self->get_tag('input_append_button') ) {
        $rendered_widget = $self->do_prepend_append($rendered_widget);
    }
    elsif( lc $self->widget eq 'checkbox' ) {
        $rendered_widget = $self->wrap_checkbox($result, $rendered_widget, 'label')
    }

    $output .= "\n$rendered_widget";
    # dynamic after element stuff
    for ( $self->get_tag('build_after_element') ) {
        next unless length;
        my $text = $self->form->$_;
        $output .= qq{\n<span class="help-inline">$text</span>}
    }
    # extra after element stuff
    for ( $self->get_tag('after_element') ) {
        $output .= qq{\n<span class="help-inline">$_</span>}
    }
    # various 'help-inline' bits: errors, warnings
    unless( $self->get_tag('no_errors') ) {
        $output .= qq{\n<span class="help-block">$_</span>}
            for $result->all_errors;
        $output .= qq{\n<span class="help-block">$_</span>} for $result->all_warnings;
    }
    # close 'control' div
    $output .= '</div>';
    # close wrapper
    $output .= "\n</div>" if $self->do_wrapper;
    return "$output";
}

sub do_prepend_append {
    my ( $self, $rendered_widget ) = @_;

    my @class;
    if( my $ip_tag = $self->get_tag('input_prepend' ) ) {
        $rendered_widget = qq{<span class="add-on">$ip_tag</span>$rendered_widget};
        push @class, 'input-prepend';
    }
    if ( my $ia_tag = $self->get_tag('input_append' ) ) {
        $rendered_widget = qq{$rendered_widget<span class="add-on">$ia_tag</span>};
        push @class, 'input-append';
    }
    if ( my $iab_tag = $self->get_tag('input_append_button') ) {
        my @buttons = ref $iab_tag eq 'ARRAY' ? @$iab_tag : ($iab_tag);
        foreach my $btn ( @buttons ) {
            $rendered_widget = qq{$rendered_widget<button type="button" class="btn">$btn</button>};
        }
        push @class, 'input-append';
    }
    my $attr = process_attrs( { class => \@class } );
    $rendered_widget =
qq{<div$attr>
  $rendered_widget
</div>};
    return $rendered_widget;
}

1;
