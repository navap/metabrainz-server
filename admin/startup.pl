#!/home/httpd/metabrainz/metabrainz/bin/perl -w
# vi: set ts=4 sw=4 :

use strict;
use warnings;

use lib "/home/httpd/metabrainz/metabrainz/lib";

# Make sure we are in a sane environment.
$ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/
    or die "GATEWAY_INTERFACE not Perl!";

use Apache::Registry;
use Apache::Session;
use DBI;
use DBD::Pg;

use MetaBrainz::Server::Defs;

# Loading the Mason handler preloads the pages, so the other MusicBrainz
# modules must be ready by this point.
use MetaBrainz::Server::Mason;

# Load the metabrainz stuff
use MetaBrainz::Server::Mason;
use MetaBrainz::Server::Defs;
use MetaBrainz::Server::Handlers;
use MetaBrainz::Server::Donation;
use MetaBrainz::Server::Receipt;

1;
# eof startup.pl
