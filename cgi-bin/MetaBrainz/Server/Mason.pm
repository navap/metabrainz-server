#!/home/httpd/musicbrainz/mb_server/cgi-bin/perl -w
# vi: set ts=4 sw=4 :

use strict;

use HTML::Mason::ApacheHandler;
use HTML::Mason;

package MetaBrainz::Server::Mason;

use Apache::Constants qw( DECLINED NOT_FOUND );
use MetaBrainz::Server::Defs;

sub preload_files
{
	my %files;

	use File::Find qw( find );
	my $len = length(&MetaBrainz::Server::Defs::HTDOCS_ROOT);
	my $recurse = sub {
		my ($dir, $patt, $norec) = @_;
		$dir = &MetaBrainz::Server::Defs::HTDOCS_ROOT . $dir;
		find(
			{
				no_chdir => 1,
				wanted => sub {
					if (-d $_)
					{
						$File::Find::prune = 1, return
							if $_ =~ /\/CVS$/
							or ($norec and $_ ne $dir);
					} elsif (-f _) {
						my $path = substr($_, $len);
						$files{$path} = 1 if $path =~ /$patt/;
					}
				},
			},
			$dir,
		);
	};

	&$recurse("", qr/\.(html|inc)$/, 1);
	&$recurse("/comp", qr/^/);

	for my $t (qw(
		/bare
		/cdi
		/development
		/freedb
		/mod
		/news
		/popup
		/products
		/support
		/tagger
		/user
	)) {
		&$recurse($t,  qr/\.(html|inc)$/);
	}

	# Preloading seems to sometimes forget to import '$r'.  This saves
	# us having to declare '$r' in whichever component happens to complain at
	# server startup time.
	{
		package MetaBrainz::Server::ComponentPackage;
		use vars '$r';
	}

	[ sort keys %files ];
}

sub get_handler
{
	# The in_package value here is the default, but it's worth
	# stating that we *depend* upon that default.
	my $compiler = HTML::Mason::Compiler::ToObject->new(
		default_escape_flags=> 'h',
		in_package			=> "MetaBrainz::Server::ComponentPackage",
	);

	my $handler = HTML::Mason::ApacheHandler->new(
		compiler			=> $compiler,
		comp_root			=> &MetaBrainz::Server::Defs::HTDOCS_ROOT,
		data_dir			=> &MetaBrainz::Server::Defs::MASON_DIR,
        #preloads			=> preload_files(),
		apache_status_title	=> __PACKAGE__." status",
		error_mode			=> (&MetaBrainz::Server::Defs::DB_STAGING_SERVER ? "output" : "fatal"),
	);

	# Install our minimal HTML encoder as the default.  This leaves
	# top-bit-set characters alone.
	$handler->interp->set_escape( h => \&MetaBrainz::Server::MetaBrainz::encode_entities );

	my $u = Apache->server->uid;
	my $g = Apache->server->gid;

	if (($> != $u or $) != $g) and ($>==0 or $<==0))
	{
		# Running as root?  "chown" MASON_DIR to the Apache user and group
		# we're going to be serving requests under.
		# Mason claims to do this itself, but it doesn't seem to work :-(

		my @chown;
		use File::Find qw( find );
		find(
			{
				no_chdir => 1,
				follow => 0,
				wanted => sub {
					my @s = stat $_;
					push @chown, $_
						unless $s[4]==$u and $s[5]==$g;
				},
			},
			&MetaBrainz::Server::Defs::MASON_DIR,
		);

		my $changed = chown $u, $g, @chown;
		warn "chown (".@chown." files): only changed $changed files ($!)\n"
			if $changed != @chown;
	}

	$handler;
}

our $ah = get_handler();

sub handler
{
    my ($r) = @_;

	{
		my $uri = $r->uri;
		return NOT_FOUND if $uri =~ m[/comp/];
		return NOT_FOUND if $uri =~ /\.inc$/;
	}

    return DECLINED if (!defined $r->content_type);
    return DECLINED if $r->content_type && $r->content_type !~ m[^text/html\b]io;

    package MetaBrainz::Server::ComponentPackage;

	# Make these available to all components:
	use MetaBrainz::Server::MetaBrainz qw( encode_entities );
	use URI::Escape qw( uri_escape );

    use vars qw(%session %pnotes);
    untie %session;
    %session = ();
    %pnotes = ();

	{
		my $req = Apache::Request->instance($r);
		$pnotes{'ispopup'} = ($req->param("ispopup") ? 1 : "");
	}

    my $ret = eval { $ah->handle_request($r) };
	my $err = $@;
	die $err if $err ne "";

    $ret;
}

1;
# eof Mason.pm
