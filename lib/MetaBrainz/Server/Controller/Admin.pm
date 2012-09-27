package MetaBrainz::Server::Controller::Admin;
use Moose;

BEGIN { extends 'MusicBrainz::Server::Controller' };

sub index : Path Args(0)
{
    my ($self, $c) = @_;

    $c->authenticate({ realm => "metabrainz" });
}

1;
