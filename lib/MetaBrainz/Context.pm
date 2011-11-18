package MetaBrainz::Context;
use Moose;
use namespace::autoclean;

use DBDefs;
use aliased 'MusicBrainz::Server::DatabaseConnectionFactory';

extends 'MusicBrainz::Server::Context';

sub _build_conn {
    return DatabaseConnectionFactory->get_connection('METABRAINZ');
}

1;
