package MetaBrainz::Types;

use strict;
use warnings;

use DateTime ();
use DateTime::Format::Pg;

use MooseX::Types::Moose qw( Int Str );
use MusicBrainz::Server::Constants qw( :quality :election_status :vote :edit_status );

use namespace::clean;

use MooseX::Types -declare => [
    qw( DateTime AutoEditorElectionStatus VoteOption EditStatus Quality )
];

class_type 'DateTime';

subtype DateTime, as 'DateTime';

coerce DateTime,
    from Str,
    via { DateTime::Format::Pg->parse_datetime($_) };

1;
