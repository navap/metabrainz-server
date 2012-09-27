package MetaBrainz::Server::Controller::Donate;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

use Scalar::Util qw( looks_like_number );
use URI;

sub paypal : Local
{
    my ($self, $c) = @_;

    my $amount  = looks_like_number($c->req->params->{amount})
                    ? $c->req->params->{amount} : undef;
    my $recur  = looks_like_number($c->req->params->{recur})
                    ? $c->req->params->{recur} : undef;

    $c->stash(
        amount => $amount,
        recur => $recur,
    );
}

sub complete : Local { }
sub cancelled : Local { }
sub paypal_ipn : Path('paypal-ipn') {
    my ($self, $c) = @_;

    my $encoder = URI->new;
    $encoder->query_form(
        [ map { $_, $c->req->params->{$_} }
              @{ $c->req->_body->param_order }
        ]
    );

    if (!$c->model('Donation')->verify_paypal_transaction($encoder->query)) {
        $c->res->status(403);
        $c->detach;
    }

    $c->model('Donation')->try_log_donation($c->req->params);
    $c->res->body('');
    $c->res->status(200);
    $c->detach;
}

sub index : Path Args(0)
{
    my ($self, $c) = @_;
}

sub add : Path('/admin/add-donation') {
    my ($self, $c) = @_;

    $c->authenticate({ realm => "metabrainz" });

    my $form = $c->form(form => 'Donation');
    if ($c->form_posted && $form->submitted_and_valid($c->req->params)) {
        $c->model('Donation')->manually_add($form->value);
        $c->res->redirect(
            $c->uri_for_action('/donations/by_date'));
    }
}

1;
