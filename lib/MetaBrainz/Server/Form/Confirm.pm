package MetaBrainz::Server::Form::Confirm;
use HTML::FormHandler::Moose;
extends 'MusicBrainz::Server::Form';

has '+name' => ( default => 'confirm' );


1;
