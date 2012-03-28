#!/usr/bin/env perl
use 5.10.0;

use inc::Module::Install;

name 'MetaBrainz-Server';
abstract 'MetaBrainz web server';
author 'MetaBrainz Foundation';
license 'gpl';
version_from 'lib/MetaBrainz/Server.pm';

requires 'Catalyst::Plugin::Unicode::Encoding' => '1.2';
requires 'Catalyst::Action::RenderView' => '0.09';
requires 'Catalyst::Runtime' => '5.90007';
requires 'Catalyst::View::TT' => '0.29';
requires 'DBD::Pg' => '2.11.8';
requires 'DateTime' => '0.72';
requires 'DateTime::Format::Pg' => '0.16004';
requires 'DateTime::Format::Strptime' => '1.5000';
requires 'DBIx::Connector';
requires 'HTML::FormHandler' => '0.36002';
requires 'HTTP::Request::Common' => '6.00';
requires 'LWP::UserAgent' => '6.03';
requires 'MIME::Lite' => '3.028';
requires 'Moose' => '2.0402';
requires 'MooseX::Types' => '0.16';
requires 'PDF::API2' => '2.0.19';
requires 'URI' => '1.59';
requires 'aliased' => '0.30';
requires 'namespace::autoclean' => '0.13';
requires 'namespace::clean' => '0.23';

# These are only needed by MusicBrainz::Server. Would be much simpler if
# stuff was broken apart and on CPAN.
requires 'Cache';
requires 'Catalyst::Plugin::StackTrace' => '0.09',
requires 'Clone';
requires 'CSS::Minifier';
requires 'Date::Calc' => '5.8';
requires 'Data::Compare';
requires 'Data::Page' => '2.01';
requires 'Data::UUID::MT' => '0.004';
requires 'Digest::MD5::File' => '0.07';
requires 'Exception::Class' => '1.29';
requires 'HTML::TreeBuilder::XPath';
requires 'HTML::Tiny' => '1.05';
requires 'IO::All';
requires 'Javascript::Closure';
requires 'Locale::TextDomain' => '1.16';
requires 'MooseX::Singleton';
requires 'MooseX::Types::Structured' => '0.24';
requires 'Readonly' => '1.03';
requires 'Text::Unaccent';
requires 'Text::WikiFormat' => '0.790';
requires 'XML::Simple' => '2.14';

auto_install;
WriteAll;
