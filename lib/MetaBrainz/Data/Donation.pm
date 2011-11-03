package MetaBrainz::Data::Donation;
use Moose;
use namespace::autoclean;

use MusicBrainz::Server::Data::Utils qw( query_to_list_limited );

with 'MusicBrainz::Server::Data::Role::Sql',
     'MusicBrainz::Server::Data::Role::NewFromRow';

sub _entity_class { 'MetaBrainz::Entity::Donation' }

sub _column_mapping {
    return {
        first_name => 'first_name',
        last_name => 'last_name',
        email => 'email',
        editor => 'moderator',
        fee => 'fee',
        amount => 'amount',
        memo => 'memo',
        date => 'payment_date'
    }
}

sub get_all {
    my ($self, $limit, $offset) = @_;

    return query_to_list_limited(
        $self->sql, $offset, $limit,
        sub { $self->_new_from_row(@_) },
        'SELECT * FROM donation ORDER BY payment_date DESC OFFSET ?',
        $offset
    );
}

sub get_all_by_amount {
    my ($self, $limit, $offset) = @_;

    return query_to_list_limited(
        $self->sql, $offset, $limit,
        sub { shift },
        'SELECT *
         FROM (
             SELECT first_name, last_name, moderator AS editor, sum(amount) as amount,
               sum(fee) as fee
             FROM donation
             GROUP BY first_name, last_name, moderator
         ) s
         ORDER BY amount DESC
         OFFSET ?',
        $offset
    );
}

1;