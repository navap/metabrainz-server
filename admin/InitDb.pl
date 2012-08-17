#!/usr/bin/env perl

use warnings;
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 2002 Robert Kaye
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

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use DBDefs;

use aliased 'MusicBrainz::Server::DatabaseConnectionFactory' => 'Databases';

my $READWRITE = Databases->get("METABRAINZ");

# Register a new database connection as the system user, but to the MB
# database
my $SYSTEM = Databases->get("SYSTEM");
my $SYSMB  = $SYSTEM->meta->clone_object(
    $SYSTEM,
    database => $READWRITE->database,
    schema => $READWRITE->schema
);
Databases->register_database("SYSMB", $SYSMB);

my $psql = "psql";
my $path_to_pending_so;
my $fFixUTF8 = 0;
my $fCreateDB;
my $tmp_dir;

use Getopt::Long;

my $fEcho = 0;
my $fQuiet = 0;

my $sqldir = "$FindBin::Bin/sql";
-d $sqldir or die "Couldn't find SQL script directory";

sub RunSQLScript
{
    my ($db, $file, $startmessage, $path) = @_;
    $startmessage ||= "Running $file";
    print localtime() . " : $startmessage ($file)\n";

    $path ||= $sqldir;   

    my $opts = $db->shell_args;
    my $echo = ($fEcho ? "-e" : "");
    my $stdout = ($fQuiet ? ">/dev/null" : "");

    $ENV{"PGOPTIONS"} = "-c search_path=" . $db->schema;
    $ENV{"PGPASSWORD"} = $db->password;
    print "$psql $echo -f $path/$file $opts 2>&1 $stdout |\n";
    open(PIPE, "$psql $echo -f $path/$file $opts 2>&1 $stdout |")
        or die "exec '$psql': $!";
    while (<PIPE>)
    {
        print localtime() . " : " . $_;
    }
    close PIPE;

    die "Error during $file" if ($? >> 8);
}

{
    my $mb;
    my $sql;
    sub get_sql
    {
        my ($name) = shift;
        return Databases->get_connection($name)->sql;
    }
}

sub Create
{
    my $createdb = $_[0];
    my $system_sql;

    # Check we can find these programs on the path
    for my $prog (qw( pg_config createuser createdb createlang ))
    {
        next if `which $prog` and $? == 0;
        die "Can't find '$prog' on your PATH\n";
    }

    # Figure out the name of the system database
    my $sysname;
    if ($createdb eq 'READWRITE' || $createdb eq 'READONLY')
    {
        $sysname = "SYSTEM";
    }
    else
    {
        $sysname = $createdb . "_SYSTEM";
        $sysname = "SYSTEM" if not defined Databases->get($sysname);
    }

    my $db = Databases->get($createdb);

    {
        # Check the cluster uses the C locale
        $system_sql = get_sql($sysname);

        my $username = $db->username;

        if (!($system_sql->select_single_value(
            "SELECT 1 FROM pg_shadow WHERE usename = ?", $username)))
        {
            my $passwordclause = "";
            $passwordclause = "PASSWORD '$_'"
                if local $_ = $db->password;

            $system_sql->auto_commit;
            $system_sql->do(
                "CREATE USER $username $passwordclause NOCREATEDB NOCREATEUSER",
            );
        }
    }

    my $dbname = $db->database;
    print localtime() . " : Creating database '$dbname'\n";
    $system_sql->auto_commit;
    my $dbuser = $db->username;
    $system_sql->do(
        "CREATE DATABASE $dbname WITH OWNER = $dbuser ".
        "TEMPLATE template0 ENCODING = 'UNICODE' ".
        "LC_CTYPE='C' LC_COLLATE='C'"
    );

    # You can do this via CREATE FUNCTION, CREATE LANGUAGE; but using
    # "createlang" is simpler :-)
    my $sys_db = Databases->get($sysname);
    my $sys_in_thisdb = $sys_db->meta->clone_object($sys_db, database => $dbname);
    my @opts = $sys_in_thisdb->shell_args;
    splice(@opts, -1, 0, "-d");
    push @opts, "plpgsql";
    $ENV{"PGPASSWORD"} = $sys_db->password;
    system "createlang", @opts;
    print "\nFailed to create language -- its likely to be already installed, continuing.\n" if ($? >> 8);
}

sub CreateRelations
{
    my $import = shift;

    my $opts = $READWRITE->shell_args;
    $ENV{"PGPASSWORD"} = $READWRITE->password;
    system(sprintf("echo \"CREATE SCHEMA %s\" | $psql $opts", $READWRITE->schema));
    die "\nFailed to create schema\n" if ($? >> 8);

    RunSQLScript($READWRITE, "CreateTables.sql", "Creating tables ...");

    if ($import)
    {
        local $" = " ";
        my @opts = "--ignore-errors";
        push @opts, "--fix-broken-utf8" if ($fFixUTF8);
        push @opts, "--tmp-dir=$tmp_dir" if ($tmp_dir);
        system($^X, "$FindBin::Bin/MBImport.pl", @opts, @$import);
        die "\nFailed to import dataset.\n" if ($? >> 8);
    }

    RunSQLScript($READWRITE, "CreatePrimaryKeys.sql", "Creating primary keys ...");
    RunSQLScript($READWRITE, "CreateIndexes.sql", "Creating indexes ...");
    RunSQLScript($READWRITE, "SetSequences.sql", "Setting raw initial sequence values ...");

    print localtime() . " : Optimizing database ...\n";
    $opts = $READWRITE->shell_args;
    $ENV{"PGPASSWORD"} = $READWRITE->password;
    system("echo \"vacuum analyze\" | $psql $opts");
    die "\nFailed to optimize database\n" if ($? >> 8);

    print localtime() . " : Initialized and imported data into the database.\n";
}

sub Usage
{
   die <<EOF;
Usage: InitDb.pl [options] [file] ...

Options are:
     --psql=PATH         Specify the path to the "psql" utility
     --postgres=NAME     Specify the name of the system user
     --createdb          Create the database, PL/PGSQL language and user
  -i --import            Prepare the database and then import the data from
                         the given files
  -c --clean             Prepare a ready to use empty database
     --[no]echo          When running the various SQL scripts, echo the commands
                         as they are run
  -q, --quiet            Don't show the output of any SQL scripts
  -h --help              This help
     --fix-broken-utf8   replace invalid UTF-8 byte sequences with the special
                         Unicode "replacement character" U+FFFD.
                         (Should only be used, when an import without the option
                         fails with an "ERROR:  invalid UTF-8 byte sequence detected"!
                         see also `MBImport.pl --help')

After the import option, you may specify one or more MusicBrainz data dump
files for importing into the database. Once this script runs to completion
without errors, the database will be ready to use. Or it *should* at least.

Since all non-option arguments are passed directly to MBImport.pl, you can
pass additional options to that script by using "--".  For example:

  InitDb.pl --createdb --echo --import -- --tmp-dir=/var/tmp *.tar.bz2

EOF
}

my $mode = "MODE_IMPORT";

GetOptions(
    "psql=s"              => \$psql,
    "createdb"            => \$fCreateDB,
    "empty-database"      => sub { $mode = "MODE_NO_TABLES" },
    "import|i"            => sub { $mode = "MODE_IMPORT" },
    "clean|c"             => sub { $mode = "MODE_NO_DATA" },
    "with-pending=s"      => \$path_to_pending_so,
    "echo!"               => \$fEcho,
    "quiet|q"             => \$fQuiet,
    "help|h"              => \&Usage,
    "fix-broken-utf8"     => \$fFixUTF8,
    "tmp-dir=s"           => \$tmp_dir
) or exit 2;

print localtime() . " : InitDb.pl starting\n";
my $started = 1;

if ($fCreateDB)
{
    Create("METABRAINZ");
}

if ($mode eq "MODE_NO_TABLES") { } # nothing to do
elsif ($mode eq "MODE_NO_DATA") { CreateRelations() }
elsif ($mode eq "MODE_IMPORT") { CreateRelations(\@ARGV) }

END {
    print localtime() . " : InitDb.pl "
        . ($? == 0 ? "succeeded" : "failed")
        . "\n"
        if $started;
}

# vi: set ts=4 sw=4 :
