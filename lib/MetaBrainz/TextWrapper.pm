package MetaBrainz::TextWrapper;
use Moose;

use PDF::API2;

has text => (
    required => 1,
    is => 'ro'
);

has [qw( x y )] => (
    default => 0,
    is => 'rw',
);

has [qw( _lf size )] => (
    is => 'rw',
);

sub move_to {
    my ($self, $x, $y) = @_;

    $self->x($x);
    $self->y($y);
}

sub select_font {
    my ($self, $font, $size) = @_;

    $self->size($size);
    $self->text->font($font, $size);
    $self->_lf(int($size * 1.2));
}

sub println {
    my ($self, $text) = @_;

    $self->text->translate($self->x, $self->y);
    $self->text->text($text);
    $self->lf;
}

sub rprintln {
    my ($self, $text) = @_;

    $self->text->translate($self->x, $self->y);
    $self->text->text_right($text);
    $self->lf;
}

sub cprintln {
    my ($self, $text) = @_;

    $self->text->translate($self->x, $self->y);
    $self->text->text_center($text);
    $self->lf;
}

sub lf {
    my ($self, $text) = @_;
    $self->y($self->y - $self->_lf);
}

1;
