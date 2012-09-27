package MetaBrainz::Server::Filters;

use strict;
use warnings;
use Data::Dumper;

# This is pretty much cheating, but it works. :)
sub utc_date
{
    my $date = shift;
    $date =~ s/T/ /g;
    return "$date utc";
}

1;
