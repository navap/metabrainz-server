package MetaBrainz::Server::Controller::Donations;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub by_date : Path('by-date') {
    my ($self, $c) = @_;

    my $donations = $self->_load_paged($c, sub {
        $c->model('Donation')->get_all(shift, shift);
    });

    $c->stash( donations => $donations );
}

sub by_amount : Path('by-amount') {
    my ($self, $c) = @_;

    my $donations = $self->_load_paged($c, sub {
        $c->model('Donation')->get_all_by_amount(shift, shift);
    });

    $c->stash( donations => $donations );
}

1;
