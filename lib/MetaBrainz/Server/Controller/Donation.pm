package MetaBrainz::Server::Controller::Donation;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub by_date : Path('by-date') {
    my ($self, $c) = @_;

    my $donations = $self->_load_paged($c, sub {
        $c->model('Donation')->get_all(shift, shift);
    });

    $c->stash( donations => $donations );
}

1;
