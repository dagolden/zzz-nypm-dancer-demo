# README

## Description

This software repository contains a minimal demonstration of a Perl Dancer web
application.  The application demonstrates user registration, email
confirmation, and lost password reset.

Technology demonstrated includes:

* [Perl Dancer](http://perldancer.org) (version 1)
* [MongoDB](http://www.mongodb.org/) and the [Mongoose](http://p3rl.org/Mongoose) ORM for Perl
* [Xslate](http://xslate.org/) template engine
* [HTML::FormHandler](http://p3rl.org/HTML::FormHandler) (and customization of it)
* [Authen::Passphrase::BlowfishCrypt](http://p3rl.org/Authen::Passphrase::BlowfishCrypt) bcrypt password hashing
* [Postmark](http://postmarkapp.com/) email delivery

## Installing dependencies

The easiest way to install Perl dependencies is to install
[cpanminus](http://p3rl.org/App::cpanminus) first and run it from the checked
out repository directory.

    $ cpanm --installdeps .

You will also need to [install MongoDB](http://docs.mongodb.org/manual/installation/) on your
system.

## Running the demo

Once all dependencies are installed, use the 'plackup' command:

    $ plackup bin/app.pl

Then browse to the web page indicated in the console, typically http://0:5000/

## Sources

All sources included are subject to their own open-source license terms:

* [Bootstrap](http://twitter.github.com/bootstrap/index.html)
* [JQuery](http://jquery.com/)
* [Font Awesome](http://fortawesome.github.com/Font-Awesome/)

Some source files generated by or adapted from additional sources, also under
their own open-source license terms:

* [Perl Dancer](http://perldancer.org/)
* ["Dancer Template, now with more Cowbell"](https://github.com/agordon/dancer_bootstrap_fontawesome_template)

## License

All other files not from the above named sources are copyright (c) 2013 by David A. Golden and
are licensed under The Apache License, Version 2.0, January 2004
