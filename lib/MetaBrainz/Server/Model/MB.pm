package MetaBrainz::Server::Model::MB;
use Moose;

extends 'Catalyst::Model';

use aliased 'MusicBrainz::Server::DatabaseConnectionFactory';

use MusicBrainz::Server::Context;

has 'context' => (
    isa        => 'MusicBrainz::Server::Context',
    is         => 'rw',
    lazy_build => 1,
    handles    => [qw( cache dbh )] # XXX Hack - Model::Feeds should be in Data
);

sub _build_context {
    my $self = shift;

    return MusicBrainz::Server::Context->new(
        conn => DatabaseConnectionFactory->get_connection('METABRAINZ')
    );
}


sub BUILD {
    my ($self) = @_;
    $self->inject(
        FileCache => 'MusicBrainz::Server::Data::FileCache',
        static_dir => '/home/ollie/Work/MetaBrainz/root/static'
    );
    $self->inject(
        Donation => 'MetaBrainz::Data::Donation'
    )
}

sub inject {
    my ($self, $name, $class, %opts) = @_;
    Class::MOP::load_class($class);

    my $dao = $class->new(c => $self->context, %opts);
    Class::MOP::Class->create(
        "MetaBrainz::Server::Model::$name" =>
            methods => {
                ACCEPT_CONTEXT => sub {
                    return $dao
                }
            });
}

sub expand_modules {
    my $self = shift;
    return
        map { "MetaBrainz::Server::Model::$_" }
            qw( Donation FileCache );
}

1;
