package MetaBrainz::Entity::Donation;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( Num Str );

use MusicBrainz::Server::Types;

has date => (
    isa => 'DateTime',
    is => 'rw',
    coerce => 1
);

has [qw( first_name last_name email editor street city state postcode country memo )] => (
    isa => Str,
    is => 'rw'
);

has [qw( fee amount )] => (
    isa => Num,
    is => 'rw',
);

1;
