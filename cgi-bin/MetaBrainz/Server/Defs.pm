#!/usr/bin/perl -w
# vi: set ts=8 sw=4 :
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 1998 Robert Kaye
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   $Id$
#____________________________________________________________________________

package MetaBrainz::Server::Defs;

################################################################################
# Directories
################################################################################

# The Server Root, i.e. the parent directory of admin, cgi-bin and htdocs
sub MB_SERVER_ROOT	{ "/home/httpd/metabrainz/metabrainz" }
# The htdocs directory
sub HTDOCS_ROOT		{ MB_SERVER_ROOT() . "/htdocs" }

# Mason's data_dir
sub MASON_DIR		{ "/home/httpd/metabrainz/mason" }


################################################################################
# The Database
################################################################################

require MetaBrainz::Server::Database;
MetaBrainz::Server::Database->register_all(
    {
	# How to connect when we need read-write access to the database
	READWRITE => {
	    database	=> "metabrainz",
	    username	=> "musicbrainz_user",
	    password	=> "",
	    host	=> "",
	    port	=> "",
	},
	# How to connect for read-only access.  See "DB_IS_REPLICATED" (below)
	READONLY => undef,
	# How to connect for administrative access
	SYSTEM	=> {
	    database	=> "template1",
	    username	=> "postgres",
	    password	=> "",
	    host	=> "",
	    port	=> "",
	},
    },
);

# The schema sequence number.  Must match the value in
# replication_control.current_schema_sequence.
sub DB_SCHEMA_SEQUENCE { 0 }

# Replication slaves should prevent users from making any changes to the
# database.  Note that this setting is closely tied to the "READONLY" key,
# above.  See the INSTALL file for more information.
sub DB_IS_REPLICATED { 0 }

################################################################################
# PayPal Logging Settings
################################################################################

sub PAYPAL_PRIMARY_EMAIL { 'paypal@metabrainz.org' };
sub PAYPAL_COMPLETE_LOG_FILE { "/var/log/metabrainz/paypal/complete" };
sub PAYPAL_PENDING_LOG_FILE { "/var/log/metabrainz/paypal/pending" };
sub PAYPAL_ERROR_LOG_FILE { "/var/log/metabrainz/paypal/error" };
sub PAYPAL_INVALID_LOG_FILE { "/var/log/metabrainz/paypal/invalid" };

################################################################################
# Mail Settings
################################################################################

sub SMTP_SERVER { "localhost" }

# If this is not undef, it lists a file to where all mail should be spooled
# (instead of being sent via SMTP_SERVER)
sub DEBUG_MAIL_SPOOL { undef }

# This value should be set to some secret value for your server.  Any old
# string of stuff should do; something suitably long and random, like for
# passwords.  However you MUST change it from the default
# value (the empty string).  This is so an attacker can't just look in CVS and
# see the default secret value, and then use it to attack your server.
sub SMTP_SECRET_CHECKSUM { "biteme" }
sub EMAIL_VERIFICATION_TIMEOUT { 604800 } # one week

################################################################################
# Cache Settings
################################################################################
            
# Show MISS, HIT, SET etc
sub CACHE_DEBUG { 1 }

# Default expiry time in seconds.  Use 0 for "never".
sub CACHE_DEFAULT_EXPIRES { 3600 }

# Default delete time in seconds.  Use 0 means allow re-insert straight away.
sub CACHE_DEFAULT_DELETE { 10 }

# Cache::Memcached options 
our %CACHE_OPTIONS = (
        servers => [ '127.0.0.1:11211' ],
        debug => 0,
        );
sub CACHE_OPTIONS { \%CACHE_OPTIONS }

################################################################################
# Other Settings
################################################################################

# If this is the live MusicBrainz server, change this to 'undef'.
# If it's not, set it to some word describing the type of server; e.g.
# "development", "test", etc.
# Mainly this option just affects the banner across the top of each page;
# also there are a couple of "debug" type features which are only active
# when not on the live server.
sub DB_STAGING_SERVER { "" }

# This defines the version of the server.  Only used by things which display
# the server version, e.g. at the foot of each web page.  Basically it can be
# whatever you want.
sub VERSION { "TRUNK" }

# If this file exists (and is writeable by the web server), debugging
# information is logged here.
sub DEBUG_LOG	{ "/tmp/musicbrainz-debug.log" }

# How long (in seconds) a web/rdf session can go "idle" before being timed out
sub WEB_SESSION_SECONDS_TO_LIVE { 3600 * 3 }
sub RDF_SESSION_SECONDS_TO_LIVE { 3600 * 1 }

1;
# eof Defs.pm
