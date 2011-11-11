package MetaBrainz::Server::Controller::Admin::WikiDoc;
use Moose;

BEGIN { extends 'MusicBrainz::Server::Controller' };

sub index : Path Args(0)
{
    my ($self, $c) = @_;

    my $index = $c->model('WikiDocIndex')->get_index;

    my @pages;
    foreach my $page (sort { lc $a cmp lc $b } keys %$index) {
        my $info = { id => $page, version => $index->{$page} };
        push @pages, $info;
    }

    my @wiki_pages = $c->model('WikiDocIndex')->get_wiki_versions($index);
    my $updates_required = 0;

    # Merge the data retreived from the wiki with the transclusion table
    for (my $i = 0; $i < @pages; $i++) {
        if (defined $wiki_pages[$i] && $pages[$i]->{id} eq $wiki_pages[$i]->{id}) {
            $pages[$i]->{wiki_version} = $wiki_pages[$i]->{wiki_version};

            # We want to know if updates are required so
            # that we can update the template accordingly.
            $updates_required = 1 if $pages[$i]->{version} != $pages[$i]->{wiki_version};
        } else {
            # Should not reach here.
            if ($wiki_pages[$i]->{id}) {
                # If we reached here there was a sorting problem.
                $c->log->error("'$pages[$i]->{id}' from the transclusion table doesn't match '$wiki_pages[$i]->{id}' from the wiki");
            } else {
                # If we reached here there was a problem accessing the api data.
                # Enable updates_required to let the user know there was a problem.
                $updates_required = 1;
            }
        }
    }

    $c->stash(
        pages            => \@pages,
        updates_required => $updates_required
    );
}

sub create : Local Args(0) RequireAuth(wiki_transcluder)
{
    my ($self, $c) = @_;

    my $form = $c->form( form => 'Admin::WikiDoc::Add' );

    if ($c->form_posted && $form->process( params => $c->req->params )) {
        $c->model('WikiDocIndex')->set_page_version(
            $form->field('page')->value,
            $form->field('version')->value
        );

        my $url = $c->uri_for_action('/admin/wikidoc/index');
        $c->response->redirect($url);
        $c->detach;
    }
}

sub edit : Local Args(0) RequireAuth(wiki_transcluder)
{
    my ($self, $c) = @_;

    my $page = $c->req->params->{page};
    my $version = $c->model('WikiDocIndex')->get_page_version($page);
    my $form = $c->form( form => 'Admin::WikiDoc::Edit',
                         init_object => { version => $version } );

    if ($c->form_posted && $form->process( params => $c->req->params )) {
        $c->model('WikiDocIndex')->set_page_version(
            $form->field('page')->value,
            $form->field('version')->value
        );

        my $url = $c->uri_for_action('/admin/wikidoc/index');
        $c->response->redirect($url);
        $c->detach;
    }

    $c->stash( page => $page, version => $version );
}

sub delete : Local Args(0) RequireAuth(wiki_transcluder)
{
    my ($self, $c) = @_;

    my $page = $c->req->params->{page};
    my $version = $c->model('WikiDocIndex')->get_page_version($page);
    my $form = $c->form( form => 'Confirm' );

    if ($c->form_posted && $form->process( params => $c->req->params )) {
        $c->model('WikiDocIndex')->set_page_version(
            $page,
            undef
        );

        my $url = $c->uri_for_action('/admin/wikidoc/index');
        $c->response->redirect($url);
        $c->detach;
    }

    $c->stash( page => $page, version => $version );
}

1;
