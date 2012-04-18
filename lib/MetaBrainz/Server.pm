package MetaBrainz::Server;

use Moose;
BEGIN { extends 'Catalyst' }

use aliased 'MusicBrainz::Server::Translation';

require MusicBrainz::Server::Filters;
use Catalyst qw/ Authentication /;

__PACKAGE__->config(
    name => 'MetaBrainz::Server',
    default_view => 'Default',
    encoding => 'UTF-8',
    "View::Default" => {
        FILTERS => {
            'uri_decode' => \&MusicBrainz::Server::Filters::uri_decode,
        },
        TEMPLATE_EXTENSION => '.tt',
        PRE_PROCESS => [
            'preprocess.tt'
        ],
        ENCODING => 'UTF-8',
        PLUGIN_BASE => 'MusicBrainz::Server::Plugin',
    },
    authentication => {
        default_realm => 'metabrainz',
        realms => {
            metabrainz => {
                credential => {
                    class => 'HTTP',
                    type  => 'basic',
                    password_type  => 'clear',
                    password_field => 'password'
                },
                store => {
                    class => 'Minimal',
                    users => {
                        admin => { password => &DBDefs::ADMIN_PASSWORD },
                    },
                },
            },
        }
    },
);

my @args = qw(
    StackTrace
    Unicode::Encoding
);

if (&DBDefs::CATALYST_DEBUG) {
    push @args, "-Debug";
}

__PACKAGE__->setup(@args);


__PACKAGE__->model('MB')->inject(
    FileCache => 'MusicBrainz::Server::Data::FileCache',
    static_dir => '&DBDefs::STATIC_FILES_DIR'
);

sub gettext  { shift; Translation->instance->gettext(@_) }
sub ngettext { shift; Translation->instance->ngettext(@_) }

sub form
{
    my ($c, $stash, $form_name, %args) = @_;
    die '$c->form required $stash => $form_name as arguments' unless $stash && $form_name;
    $form_name = "MetaBrainz::Server::Form::$form_name";
    Class::MOP::load_class($form_name);
    my $form = $form_name->new(%args, ctx => $c);
    $c->stash( $stash => $form );
    return $form;
}

sub form_posted {
    my $c = shift;
    return $c->req->method eq 'POST';
}

1;
