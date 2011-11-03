package MetaBrainz::Server::Model::MB;
use Moose;

extends 'Catalyst::Model';

sub BUILD {
    my ($self) = @_;
    $self->inject(
        FileCache => 'MusicBrainz::Server::Data::FileCache',
        static_dir => '/home/ollie/Work/MetaBrainz/root/static'
    );
}

sub inject {
    my ($self, $name, $class, %opts) = @_;
    Class::MOP::load_class($class);

    my $dao = $class->new(%opts);
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
    return 'MetaBrainz::Server::Model::FileCache';
}

1;
