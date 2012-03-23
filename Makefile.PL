#!/usr/bin/env perl
use 5.10.0;

use inc::Module::Install;

name 'MetaBrainz-Server';
abstract 'MetaBrainz web server';
author 'MetaBrainz Foundation';
license 'gpl';
version_from 'lib/MetaBrainz/Server.pm';

requires 'aliased' => '0.30';
requires 'Catalyst::Runtime' => '5.90007';
requires 'DateTime' => '0.72';
requires 'DateTime::Format::Pg' => '0.16004';
requires 'DateTime::Format::Strptime' => '1.5000';
requires 'HTML::FormHandler' => '0.36002';
requires 'HTTP::Request::Common' => '6.00';
requires 'LWP::UserAgent' => '6.03';
requires 'MIME::Lite' => '3.028';
requires 'Moose' => '2.0402';
requires 'MooseX::Types' => '0.16';
requires 'namespace::autoclean' => '0.13';
requires 'namespace::clean' => '0.23';
requires 'PDF::API2' => '2.0.19';
requires 'URI' => '1.59';

auto_install;
WriteAll;
