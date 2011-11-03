package MetaBrainz::Server::Controller::Root;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub index : Path Args(0) {
    my ($self, $c) = @_;
}

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    $c->stash(
        server_details => {
            development_server => 1
        }
    );
}

1;
