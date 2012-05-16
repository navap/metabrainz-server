package MetaBrainz::Entity::Donation;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( Num Str );

use MetaBrainz::Types qw( DateTime );

has date => (
    isa => DateTime,
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

has 'anon' => (
    isa => 'Bool',
    is => 'rw',
    coerce => 1
);

1;
