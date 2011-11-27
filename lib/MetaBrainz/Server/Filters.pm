package MetaBrainz::Server::Filters;

use strict;
use warnings;

use Encode;
use Try::Tiny;
use URI::Escape;

sub uri_decode
{
    my $uri = shift;
    try {
        decode('utf-8', uri_unescape($uri), Encode::FB_CROAK);
    }
    catch {
        $uri;
    }
}

1;