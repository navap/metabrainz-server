package MetaBrainz::Server::Controller::Root;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub index : Path Args(0) {
    my ($self, $c) = @_;
}

sub default : Path
{
    my ($self, $c) = @_;
    $c->detach('/error_404');
}

sub error_404 : Private
{
    my ($self, $c) = @_;

    $c->response->status(404);
    $c->stash->{template} = 'main/404.tt';
}

sub begin : Private
{
    my ($self, $c) = @_;

    $c->stash(
        wiki_server => &DBDefs::WIKITRANS_SERVER,
    );

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
