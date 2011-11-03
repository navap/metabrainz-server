package MetaBrainz::Server;

use Moose;
BEGIN { extends 'Catalyst' }

use aliased 'MusicBrainz::Server::Translation';

__PACKAGE__->config(
    name => 'MetaBrainz::Server',
    default_view => 'Default',
    encoding => 'UTF-8',
    "View::Default" => {
        TEMPLATE_EXTENSION => '.tt',
        PRE_PROCESS => [
            'preprocess.tt'
        ],
        ENCODING => 'UTF-8',
    },
    static => {
        mime_types => {
            json => 'application/json; charset=UTF-8',
        },
        dirs => [ 'static' ],
        no_logs => 1
    }
);

__PACKAGE__->setup(qw(
    Static::Simple
    StackTrace
    Unicode::Encoding
));

__PACKAGE__->model('MB')->inject(
    FileCache => 'MusicBrainz::Server::Data::FileCache',
    static_dir => '/home/ollie/Work/MetaBrainz/root/static'
);

sub gettext  { shift; Translation->instance->gettext(@_) }
sub ngettext { shift; Translation->instance->ngettext(@_) }

1;
