package MetaBrainz::Server::Controller::Doc;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub show : Path('')
{
    my ($self, $c, @args) = @_;

    # Only show Home doc via root
    $c->detach('/error_404') if $c->req->path eq 'doc/Home';

    my $ns = &DBDefs::WIKITRANS_NAMESPACE;

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
        $page->{title} =~ s/$ns//;

        $c->stash(
            id => $id,
            page => $page,
        );

        if ($bare) {
            $c->stash->{template} = 'doc/bare.tt';
        } elsif ($id eq $ns . 'Home') {
            $c->stash->{template} = 'doc/home.tt';
        } elsif (substr($id,0,-5) eq $ns . 'Annual_Report') {
            $c->stash->{template} = 'doc/annual-report.tt';
        } else {
            $c->stash->{template} = 'doc/page.tt';
        }
    }
    else {
        $c->detach('/error_404');
    }
}

1;
