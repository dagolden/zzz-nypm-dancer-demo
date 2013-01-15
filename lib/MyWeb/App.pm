package MyWeb::App;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin::Adapter;
use Dancer::Plugin::Auth::Tiny;
use Dancer::Plugin::Deferred;
use Dancer::Plugin::Mongoose;
use Dancer::Plugin::Syntax::GetPost;

use MyWeb::Form::ChangePassword;
use MyWeb::Form::Forgot;
use MyWeb::Form::Login;
use MyWeb::Form::Register;

use Crypt::Diceware qw/words/;

our $VERSION = '0.1';

hook 'before_template_render' => sub {
    my $tokens = shift;

    $tokens->{user} = session('user');

    my @route_map = qw(
      login logout register change_password forgot
    );

    for my $route (@route_map) {
        $tokens->{ $route . '_url' } = uri_for("/$route");
    }

};

#--------------------------------------------------------------------------#
# Public routes
#--------------------------------------------------------------------------#

get '/' => sub { template 'page/index' };

get_post '/login' => sub {
    my $user_obj;

    my $form = MyWeb::Form::Login->new(
        check_user => sub { $user_obj = schema("user")->find_user(shift) },
        check_password => sub { $user_obj && $user_obj->matches_password(shift) },
    );

    if ( request->is_post ) {
        $form->process( posted => 1, params => {params} );
        if ( $form->is_valid ) {
            if ( session('user') && session('user') ne $user_obj->user ) {
                # logging in as another user, so clean up the session;
                session->destroy;
            }
            session user => $user_obj->user;
            return redirect '/';
        }
    }

    return template 'form/login' => { form => $form };
};

get '/logout' => sub {
    deferred message => "You are logged out."
      if session 'user';
    session->destroy;
    return redirect '/';
};

get_post '/forgot' => sub {
    my $user_obj;

    my $form = MyWeb::Form::Forgot->new(
        cancel_url  => uri_for('/login'),
        check_user  => sub { $user_obj = schema("user")->find_user(shift) },
        check_email => sub { $user_obj = schema("user")->find_by_email(shift) },
    );

    if ( request->is_post ) {
        $form->process( posted => 1, params => {params} );
        if ( $form->is_valid ) {
            # XXX really shouldn't send password reset email unless email is verified
            # or unless params->{email} was given

            # generate reset token
            my $token = schema("token")->new(
                user => $user_obj->user,
                type => 'p',
            );
            $token->save;

            eval {
                service("postmark")->send(
                    to      => $user_obj->email,
                    from    => setting("support_email"),
                    subject => 'Did you forget your password?',
                    body    => template(
                        'emails/password_reset',
                        {
                            forgot_user => $user_obj->user,
                            token_url   => uri_for( '/confirm/' . $token->token ),
                        },
                    ),
                );
            };

            if ($@) {
                return template 'page/error' =>
                  { error => "Something went wrong. Try again later." };
            }
            else {
                return template 'page/email_sent' => {
                    go_back_text => 'Go back to login',
                    go_back_url  => uri_for("/login"),
                    token_type   => 'password reset',
                    rcpt_email   => $user_obj->email,
                };
            }
        }
    }

    template 'form/forgot' => { modal => 1, form => $form };
};

get '/dump' => sub { die };

get_post '/register' => sub {
    # if session has logged in user, that's bad; what else should we
    # but force a logout
    session->destroy
      if session('user');

    my $form = MyWeb::Form::Register->new(
        check_user_avail  => sub { !schema("user")->find_user(shift) },
        check_email_avail => sub { !schema("user")->find_by_email(shift) },
    );
    $form->field("password")->set_element_attr( "placeholder", join( " ", words(4) ) );

    if ( request->is_post ) {
        $form->process( posted => 1, params => {params} );
        if ( $form->is_valid ) {
            my $value = $form->value;

            # insert the new user
            my $user_obj =
              schema("user")->new( { user => $value->{user}, email => $value->{email} } );
            $user_obj->set_password( $value->{password} );
            $user_obj->save;
            session user => $user_obj->user;

            # generate email confirmation token
            my $token = schema("token")->new(
                user  => $user_obj->user,
                type  => 'e',
                value => $user_obj->email,
            );
            $token->save;

            eval {
                service("postmark")->send(
                    to      => $user_obj->email,
                    from    => setting("support_email"),
                    subject => 'Did you forget your password?',
                    body    => template(
                        'emails/register_email',
                        {
                            verify_email => $user_obj->email,
                            user         => $user_obj->user,
                            token_url    => uri_for( '/confirm/' . $token->token ),
                        },
                    ),
                );
            };

            if ($@) {
                deferred message => "Could not send your email confirmation: $@";
            }
            else {
                deferred message => "Please check your email to verify your email address";
            }
            return redirect '/';
        }
    }

    return template 'form/register' => { form => $form };
};

get '/confirm/:token' => sub {
    unless ( params->{token} =~ /^[a-zA-Z0-9_=-]{32}$/ ) {
        return template 'page/error' => { error => "Invalid token" };
    }

    my $token = schema("token")->find_token( params->{token} );

    if ($token) {
        $token->delete;
    }
    else {
        return template 'page/error' => { error => "Token not found" };
    }

    my $user = schema("user")->find_user( $token->user );

    unless ($user) {
        return template 'page/error' => { error => "Token has invalid user" };
    }

    # If $user doesn't match session user, then destroy session
    # so we're sure anything we do is for the user associated with the token.
    # Note -- this may not mean a token is login-equivalent; individual
    # handlers may choose to set session user again or not
    if ( session("user") && session("user") ne $user->user ) {
        session->destroy;
    }

    if ( time() > $token->expiration ) {
        return template 'page/error' => { error => "Token has expired" };
    }

    # For password reset, treat as login, but scramble password
    # so use of token is equivalent to revokation of prior password.
    # Then prompt password reset *without* requiring old password.
    # At worst -- if they manually jump out of password reset, they'll
    # only have a single session logged in
    if ( $token->type eq 'p' ) { # password reset
        session user  => $user->user; # treat as logged in
        session token => 1;           # note they arrived via token
        $user->scramble_password;
        $user->save;
        return redirect '/change_password';
    }
    elsif ( $token->type eq 'e' ) {   # email confirm
        $user->email_valid(1);
        $user->save;
        deferred message => "Your email " . $token->value . " has been verified";
        return redirect uri_for('/');
    }
    else {
        return template 'page/error' => { error => "Token not recognized" };
    }

};

#--------------------------------------------------------------------------#
# Private request paths (require login)
#--------------------------------------------------------------------------#

##get "/settings" => needs login => sub { template "private/settings" };

get_post '/change_password' => needs login => sub {
    my $from_token = session('token');

    my $user_obj = schema("user")->find_user( session 'user' )
      or return redirect '/logout';

    my $form = MyWeb::Form::ChangePassword->new(
        cancel_url => $from_token ? uri_for("/logout") : uri_for("/"),
        inactive => $from_token ? [ 'old_password', 'spacer' ] : [],
        check_old_password => sub { $user_obj->matches_password(shift) },
    );

    if ( request->is_post ) {
        $form->process( posted => 1, params => {params} );
        if ( $form->is_valid ) {
            $user_obj->set_password( $form->field("password")->value );
            $user_obj->save;
            session token    => undef;
            deferred message => "Your password has been changed";
            return redirect '/';
        }
    }

    template 'form/change_password' => {
        form       => $form,
        from_token => $from_token,
    };
};

true;
