package MetaBrainz::Server::Form::Donation;
use Moose;
use HTML::FormHandler::Moose;

extends 'MusicBrainz::Server::Form';

has '+name' => ( default => 'donation' );

has_field name => (
    type => 'Compound',
);

has_field 'name.first' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
    required => 1
);

has_field 'name.last' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
    required => 1
);

has_field email => (
    type => 'Email',
    required => 1
);

has_field can_contact => (
    type => 'Boolean'
);

has_field is_anonymous => (
    type => 'Boolean'
);

has_field address => (
    type => 'Compound',
);

has_field 'address.street' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
);

has_field 'address.city' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
);

has_field 'address.state' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
);

has_field 'address.postcode' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
);

has_field 'address.country' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
);

has_field payment_date => (
    type => 'Date',
    format => '%m-%d-%Y'
);

has_field net_amount => (
    type => 'Money',
    required => 1
);

has_field fee => (
    type => 'Money',
    required => 1
);

has_field editor_name => (
    type => '+MusicBrainz::Server::Form::Field::Text'
);

has_field memo => (
    type => 'Text'
);

1;
