package MyWeb::FormHandler::Widget::Theme::Bootstrap;

use Moose::Role;
with 'MyWeb::FormHandler::Widget::Theme::BootstrapFormMessages';

after 'before_build' => sub {
    my $self = shift;
    $self->set_widget_wrapper('+MyWeb::FormHandler::Widget::Wrapper::Bootstrap')
       if $self->widget_wrapper eq 'Simple';
};

sub build_form_element_class { ['form-horizontal'] }

1;
