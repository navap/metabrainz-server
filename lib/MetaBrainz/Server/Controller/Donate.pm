package MetaBrainz::Server::Controller::Donate;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub paypal : Local
{
    my ($self, $c) = @_;

    $c->stash(
        amount => $c->req->params->{amount},
        recur => $c->req->params->{recur},
    );
}

sub complete : Local { }
sub cancelled : Local { }

sub index : Path Args(0)
{
    my ($self, $c) = @_;
}

sub add : Path('/admin/add-donation') {
    my ($self, $c) = @_;
    my $form = $c->form(form => 'Donation');
    if ($c->form_posted && $form->submitted_and_valid($c->req->params)) {
        $c->model('Donation')->manually_add($form->value);
        $c->res->redirect(
            $c->uri_for_action('/donations/by_date'));
    }
}

1;
