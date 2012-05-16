package MetaBrainz::Data::Donation;
use Moose;
use Data::Dumper;
use namespace::autoclean;

use DateTime::Format::Pg;
use DBDefs;
use HTTP::Request::Common;
use LWP::UserAgent;
use MetaBrainz::TextWrapper;
use MusicBrainz::Server::Data::Utils qw( query_to_list_limited );
use PDF::API2;

with 'MusicBrainz::Server::Data::Role::Sql',
     'MusicBrainz::Server::Data::Role::NewFromRow';

has lwp => (
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->env_proxy(1);
        return $ua;
    }
);

sub _entity_class { 'MetaBrainz::Entity::Donation' }

sub get_by_id {
    my ($self, $id) = @_;
    my $row = $self->sql->select_single_row_hash(
        'SELECT * FROM donation WHERE id = ?', $id
    );
    return $row && $self->_new_from_row($row);
}

sub get_by_transaction_id {
    my ($self, $id) = @_;
    my $row = $self->sql->select_single_row_hash(
        'SELECT * FROM donation WHERE paypal_trans_id = ?', $id
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
        date => 'payment_date',
        anon => 'anon'
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
             WHERE anon = \'f\'
             GROUP BY first_name, last_name, moderator
         ) s
         ORDER BY amount DESC
         OFFSET ?',
        $offset
    );
}

sub get_nag_days {
    my ($self, $editor) = @_;

    my $days_per_dollar = "7.5";

    my $row = $self->sql->select_single_row_hash(
           "SELECT ((amount + fee) * $days_per_dollar) - 
                   ((extract(epoch from now()) - extract(epoch from payment_date)) / 86400) as nag
              FROM donation 
             WHERE lower(moderator) = lower(?)
          ORDER BY nag DESC 
             LIMIT 1", $editor
    );
    return (-1, 0) if !$row->{nag};
    return ($row->{nag} >= 0 ? 0 : 1, $row->{nag});
}

sub verify_paypal_transaction {
    my ($self, $query) = @_;
    $query .= '&cmd=_notify-validate';

    my $verification_request = HTTP::Request->new('POST','http://www.paypal.com/cgi-bin/webscr');
    $verification_request->content_type('application/x-www-form-urlencoded');
    $verification_request->content($query);

    my $verification_response = $self->lwp->request($verification_request);

    if ($verification_response->is_success) {
        return 1;
    }
    else {
        return 0;
    }
}

sub try_log_donation {
    my ($self, $params) = @_;

    # check that $txn_id has not been previously processed
    if ($self->get_by_transaction_id($params->{txn_id})) {
        LogTransaction("transaction id used before");
    }

    # check that $receiver_email is your Primary PayPal email
    elsif ($params->{receiver_email} ne DBDefs::PAYPAL_PRIMARY_EMAIL)
    {
        LogTransaction("not primary email");
    }

    elsif ($params->{payer_email} =~ /^yewm200/ || $params->{payer_email} eq 'gypsy313309496@aol.com')
    {
        LogTransaction("blocked donor");
    }

    elsif ($params->{payment_gross} < 0.00)
    {
        LogTransaction("Tiny donation");
    }

    elsif ($params->{'payment_status'} eq 'Completed' &&
           lc($params->{business}) ne DBDefs::PAYPAL_BUSINESS)
    {
        $self->sql->begin;

	$params->{mc_fee} = 0.0 if (!exists $params->{mc_fee});
        $self->sql->insert_row('donation', {
            first_name       => $params->{first_name},
            last_name        => $params->{last_name},
            email            => $params->{payer_email},
            moderator        => $params->{custom} || "",
            contact          => lc($params->{option_name1}) eq 'yes' ? 'y' : 'n',
            anon             => lc($params->{option_name2}) eq 'yes' ? 'y' : 'n',
            address_street   => $params->{address_street} || "",
            address_city     => $params->{address_city} || "",
            address_state    => $params->{address_state} || "",
            address_postcode => $params->{address_zip} || "",
            address_country  => $params->{address_country} || "",
            paypal_trans_id  => $params->{txn_id},
            amount           => $params->{mc_gross} - $params->{mc_fee},
            fee              => $params->{mc_fee}
        });

        $self->c->model('Receipt')->mail_donation_receipt(
            $self->get_by_transaction_id($params->{txn_id})
        );
        $self->sql->commit;

        LogTransaction("payment received");
    }

    elsif ($params->{'payment_status'} eq 'Pending')
    {
        LogTransaction("payment pending");
    }

    elsif (lc($params->{'business'}) eq DBDefs::PAYPAL_BUSINESS)
    {
        LogTransaction("non donation received");
    }

    else
    {
        LogTransaction("Other status (no error)");
    }
}

sub LogTransaction {
    my ($message) = @_;
    warn $message;
}

1;
