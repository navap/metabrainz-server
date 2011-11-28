package MetaBrainz::Server::Controller::Doc;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub show : Path('')
{
    my ($self, $c, @args) = @_;

    # Only show Home doc via root
    $c->detach('/error_404') if $c->req->path eq 'doc/Home';

    my $ns = $c->stash->{wiki_namespace};

    my $id = join '/', @args;
    $id =~ s/ /_/g;
    $id = $ns . $id;

    my $version = $c->model('WikiDocIndex')->get_page_version($id);
    my $page = $c->model('WikiDoc')->get_page($id, $version);

    if ($page && $page->canonical)
    {
        my ($path, $fragment) = split /\#/, $page->{canonical}, 2;
        $fragment = $fragment ? '#'.$fragment : '';

        $c->response->redirect($c->uri_for('/doc', $path).$fragment, 301);
        return;
    }

    # Only show pages that are in the transclusion table
    if ($page && $version) {
        my $bare = $c->req->param('bare') || 0;
        $page->{title} =~ s,$ns,,;

        $page->{h1} = $page->{title};

        # Change a few things for the home page
        if ($id eq $ns . 'Home') {
            $page->{h1} = "Welcome to MetaBrainz!";
            $page->{title} = "";
        }

        $c->stash(
            id => $id,
            page => $page,
        );
        $c->stash->{template} = $bare ? 'doc/bare.tt' : 'doc/page.tt';
    }
    else {
        $c->detach('/error_404');
    }
}

1;
