#!/usr/bin/env perl
use strict;
use warnings;

use DBDefs;
use Plack::Builder;

use MetaBrainz::Server;

builder {
    enable 'Static', path => qr{^/static/}, root => 'root';
    MetaBrainz::Server->psgi_app;
}
