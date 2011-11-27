package MetaBrainz::Server::Controller::Doc;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub show : Path('')
{
    my ($self, $c, @args) = @_;

    my $id = join '/', @args;
    $id =~ s/ /_/g;

    my $version = $c->model('WikiDocIndex')->get_page_version($id);
    my $page = $c->model('WikiDoc')->get_page($id, $version);

    if ($page && $page->canonical)
    {
        my ($path, $fragment) = split /\#/, $page->{canonical}, 2;
        $fragment = $fragment ? '#'.$fragment : '';

        $c->response->redirect($c->uri_for('/doc', $path).$fragment, 301);
        return;
    }

    if (!$page) {
        $c->detach('/error_404');
    }

    my $bare = $c->req->param('bare') || 0;

    $c->stash(
        id => $id,
        page => $page,
    );

    $c->stash->{template} = $bare ? 'doc/bare.tt' : 'doc/page.tt';
}

1;
