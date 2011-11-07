package MetaBrainz::Server::Controller::Donate;
BEGIN { use Moose; extends 'MusicBrainz::Server::Controller'; }
use namespace::autoclean;

sub paypal : Local {}
sub complete : Local { }
sub cancelled : Local { }

1;
