package MetaBrainz::Types;

use strict;
use warnings;

use DateTime ();
use DateTime::Format::Pg;

use MooseX::Types::Moose qw( Int Str );

use namespace::clean;

use MooseX::Types -declare => [
    qw( DateTime  )
];

class_type 'DateTime';

subtype DateTime, as 'DateTime';

coerce DateTime,
    from Str,
    via { DateTime::Format::Pg->parse_datetime($_) };

1;
