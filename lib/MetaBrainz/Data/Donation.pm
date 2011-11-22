package MetaBrainz::Data::Donation;
use Moose;
use namespace::autoclean;

use DateTime::Format::Pg;
use MetaBrainz::TextWrapper;
use MusicBrainz::Server::Data::Utils qw( query_to_list_limited );
use PDF::API2;

with 'MusicBrainz::Server::Data::Role::Sql',
     'MusicBrainz::Server::Data::Role::NewFromRow';

sub _entity_class { 'MetaBrainz::Entity::Donation' }

sub get_by_id {
    my ($self, $id) = @_;
    my $row = $self->sql->select_single_row_hash(
        'SELECT * FROM donation WHERE id = ?', $id
    );
    return $row && $self->_new_from_row($row);
}

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

sub manually_add {
    my ($self, $donation) = @_;
    $self->sql->begin;
    my $pg_date_formatter = DateTime::Format::Pg->new;
    my $id = $self->sql->insert_row(
        'donation',
        {
            first_name       => $donation->{name}{first},
            last_name        => $donation->{name}{last},
            email            => $donation->{email},
            moderator        => $donation->{editor_name},
            contact          => $donation->{can_contact},
            anon             => $donation->{is_anonymous},
            address_street   => $donation->{address}{street},
            address_city     => $donation->{address}{city},
            address_state    => $donation->{address}{state},
            address_postcode => $donation->{address}{postcode},
            address_country  => $donation->{address}{country},
            payment_date     => $donation->{payment_date}
                ? $pg_date_formatter->format_datetime($donation->{payment_date})
                : \'now()',
            amount           => $donation->{net_amount},
            fee              => $donation->{fee},
            memo             => $donation->{memo}
        },
        'id',
    );

    $self->c->model('Receipt')->mail_donation_receipt(
        $self->get_by_id($id)
    );

    $self->sql->commit;
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
